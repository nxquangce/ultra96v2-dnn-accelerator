from pynq import Overlay
from pynq import allocate
from pynq import MMIO
from enum import IntEnum
from PIL import Image
import numpy as np
import tflite_runtime.interpreter as tflite

import torch

import time

overlay_name = "zynqmpsoc_conv_dbg_20210622_1051"

print("=== Config hardware ===")
print(overlay_name)
print()

overlay = Overlay('./overlay/dnn/' +  overlay_name + '.bit')
model_file = './models/mobilenet_v1_1.0_224_quant.tflite'

cdma = overlay.axi_cdma_0

CDMA_BRAM_INPUT_ADDRESS = 0x80000000
CDMA_BRAM_WEIGHT0_ADDRESS = 0x90000000
CDMA_BRAM_WEIGHT1_ADDRESS = 0x90001000
CDMA_BRAM_WEIGHT2_ADDRESS = 0x90002000
CDMA_BRAM_WEIGHT3_ADDRESS = 0x90003000
CDMA_BRAM_OUTPUT0_ADDRESS = 0xA0000000
CDMA_BRAM_OUTPUT1_ADDRESS = 0xB0000000
CDMA_BRAM_OUTPUT2_ADDRESS = 0xC0000000
CDMA_BRAM_OUTPUT3_ADDRESS = 0xD0000000

MMIO_CONFIG_REG_BASE_ADDRESS = 0x00A0001000
MMIO_CONFIG_REG_ADDRESS_RANGE = 0x1000
reg = MMIO(MMIO_CONFIG_REG_BASE_ADDRESS, MMIO_CONFIG_REG_ADDRESS_RANGE)

def getbit(value, order):
    orderVal = 2**order
    tmpbin = value & orderVal
    if (tmpbin):
        return 1
    else:
        return 0

def changebit(value, order, bit):
    if (bit == 1):
        return value | (1 << order)
    else:
        return value & ~(1 << order)

class Cdma(IntEnum):
    CDMACR = 0x0
    CDMASR = 0x4
    SA = 0x18
    DA = 0x20
    BTT = 0x28

def transfer(cdma, src, dst, size):
    # Step 1
    cdmasr = cdma.read(Cdma.CDMASR)
    cdmasrIdle = getbit(cdmasr, 1)
    if (cdmasrIdle != 1):
        print("CDMA is busy..")
        return

    # Step 2
    cdmacr = cdma.read(Cdma.CDMACR)
    cdmacr = changebit(cdmacr, 12, 1) # set IOC_IrqEn
    cdmacr = changebit(cdmacr, 14, 1) # set ERR_IrqEn
    cdma.write(Cdma.CDMACR, cdmacr)

    # Step 3
    cdma.write(Cdma.SA, src)

    # Step 4
    cdma.write(Cdma.DA, dst)

    # Step 5
    cdma.write(Cdma.BTT, size)

    # Step 6
    print("Transferring...")
    cdma.read(Cdma.CDMASR)
    cdmasrIdle = getbit(cdmasr, 1)
    while (cdmasrIdle != 1):
        print(".", end="")
        cdma.read(Cdma.CDMASR)
        cdmasrIdle = getbit(cdmasr, 1)

    # Step 7-8
    cdmasr = cdma.read(Cdma.CDMASR)
    cdmasr = changebit(cdmasr, 12, 1) # clear IOC_Irq
    cdma.write(Cdma.CDMASR, cdmasr)

    print("Transfered " + str(size) + " bytes from " + str(src) + " to " + str(dst))
    print("CDMA Done.")

def reset(cdma):
    cdmacr = cdma.read(Cdma.CDMACR)
    print(type(cdmacr))
    print(cdmacr)
    cdmacr = changebit(cdmacr, 2, 1)
    print(cdmacr)
    cdma.write(Cdma.CDMACR, cdmacr)
    
def tconv2d():
    print("==== Load weight ====")
    print(model_file)
    print()
    
    time0 = time.time()
    
    interpreter = tflite.Interpreter(model_path=model_file)
    interpreter.allocate_tensors()
    
    weight_l1 = interpreter.get_tensor(8)
    weight_l1_0_3 = weight_l1[0:16]
    
    t_weight_l1_0_3 = torch.from_numpy(weight_l1_0_3)
    t_weight_l1_0_3 = np.transpose(t_weight_l1_0_3, (0, 3, 1, 2))
    
    print("==== Load input ====")
    
    time1 = time.time()
    
    image = Image.open("input224.jpg")
    data = np.asarray(image)
    input_data = np.expand_dims(data, 0)  # shape (1, y_pixels, x_pixels, n_bands)
    input_data = np.transpose(input_data, (0, 3, 1, 2))

    t_input_data = torch.from_numpy(input_data)
    
    time2 = time.time()
    
    print("==== Perform PS Conv ====")
    
    t_output = torch.nn.functional.conv2d(t_input_data, t_weight_l1_0_3, bias=None, stride=1, padding=0, dilation=1, groups=1)
    
    time3 = time.time()
    
    print(t_output.shape)
    
    print("==============================================")
    
    print("Load weight time: %s seconds" % (time1 - time0))
    print("Load data time  : %s seconds" % (time2 - time1))
    print("----------------------------------------------")
    print("Total load time : %s seconds" % (time2 - time1))
    print()
    print("PS Conv time    : %s seconds" % (time3 - time2))
    print("==============================================")
    print("Total time      : %s seconds" % (time3 - time0))
    print()
    

def main():
    print("==== Load model ====")
    print(model_file)
    print()
    
    interpreter = tflite.Interpreter(model_path=model_file)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print("==== Load input ====")
    
    start_time0 = time.time()
    
#     image = Image.open("input.jpg").resize((224,224))
    image = Image.open("input224.jpg")
    data = np.asarray(image)
    input_data = np.expand_dims(data, 0)  # shape (1, y_pixels, x_pixels, n_bands)
    input_buffer = allocate(shape=(224,224,3), dtype=np.uint8)
    input_buffer[:] = input_data

    end_time_load0 = time.time()
    
    input_size = 224*224*3
    transfer(cdma, input_buffer.physical_address, CDMA_BRAM_INPUT_ADDRESS, input_size)
    
    end_time0 = time.time()
    
#     print("Transfer input to PS")
#     in_buffer = allocate(shape=(224,224,3), dtype=np.uint8)
#     transfer(cdma, CDMA_BRAM_INPUT_ADDRESS, in_buffer.physical_address, input_size)
#     with open('output/in_fromfile.txt', 'w') as outfile:
#         for slice_2d in input_buffer:
#             np.savetxt(outfile, slice_2d, fmt='% 4d')
#     with open('output/in_readback.txt', 'w') as outfile:
#         for slice_2d in in_buffer:
#             np.savetxt(outfile, slice_2d, fmt='% 4d')
    
#     print("Load input data: %s seconds" % (end_time_load0 - start_time0))
#     print("Transfer to PL : %s seconds" % (end_time0 - end_time_load0))
#     print("Total          : %s seconds" % (end_time_load0 - start_time0))
#     print()
    
    
    print("==== Load weight ====")
    start_time1 = time.time()
    
    weight_l1 = interpreter.get_tensor(8)
    weight_l1_0 = np.concatenate((weight_l1[0], weight_l1[4], weight_l1[0], weight_l1[4], weight_l1[16], weight_l1[20], weight_l1[24], weight_l1[28]))
    weight_l1_0_buffer = allocate(shape=(24,3,3), dtype=np.uint8)
    weight_l1_0_buffer[:] = weight_l1_0
    
    weight_l1_1 = np.concatenate((weight_l1[1], weight_l1[5], weight_l1[1], weight_l1[5], weight_l1[17], weight_l1[21], weight_l1[25], weight_l1[29]))
    weight_l1_1_buffer = allocate(shape=(24,3,3), dtype=np.uint8)
    weight_l1_1_buffer[:] = weight_l1_1
    
    weight_l1_2 = np.concatenate((weight_l1[2], weight_l1[6], weight_l1[2], weight_l1[6], weight_l1[18], weight_l1[22], weight_l1[26], weight_l1[30]))
    weight_l1_2_buffer = allocate(shape=(24,3,3), dtype=np.uint8)
    weight_l1_2_buffer[:] = weight_l1_2
    
    weight_l1_3 = np.concatenate((weight_l1[3], weight_l1[7], weight_l1[3], weight_l1[7], weight_l1[19], weight_l1[23], weight_l1[27], weight_l1[31]))
    weight_l1_3_buffer = allocate(shape=(24,3,3), dtype=np.uint8)
    weight_l1_3_buffer[:] = weight_l1_3
    
    end_time_load1 = time.time()
    
    weight_size = 3*3*3*8
    transfer(cdma, weight_l1_0_buffer.physical_address, CDMA_BRAM_WEIGHT0_ADDRESS, weight_size)
    transfer(cdma, weight_l1_1_buffer.physical_address, CDMA_BRAM_WEIGHT1_ADDRESS, weight_size)
    transfer(cdma, weight_l1_2_buffer.physical_address, CDMA_BRAM_WEIGHT2_ADDRESS, weight_size)
    transfer(cdma, weight_l1_3_buffer.physical_address, CDMA_BRAM_WEIGHT3_ADDRESS, weight_size)
    
    end_time1 = time.time()
    
#     readback_buffer = allocate(shape=(54,4), dtype=np.uint8)
#     transfer(cdma, CDMA_BRAM_WEIGHT0_ADDRESS, readback_buffer.physical_address, weight_size)
#     print(readback_buffer)

    
#     print("Load weight data: %s seconds" % (end_time_load1 - start_time1))
#     print("Transfer to PL  : %s seconds" % (end_time1 - end_time_load1))
#     print("Total           : %s seconds" % (end_time_load1 - start_time1))
#     print()
    
    print("==== Perform PL Conv ====")
    input_shape = [224, 224, 3]
    weight_shape = [8, 3, 3, 3]
    stride = 1
    
    output_width = (input_shape[0] - weight_shape[1]) // stride + 1
    output_shape = [output_width, output_width, weight_shape[0]]
    inputrstcnt = output_width * input_shape[0] - 1
    num_invalid_row = input_shape[0] - output_width * stride - 1
    num_invalid_row = 0
    outputsize = output_width * output_width - 1
    conf_addr4 = (num_invalid_row << (5*4)) + (stride << (4*4)) + weight_shape[1]**2
    weightinterval = output_width ** 2 * 3 - 1
    kernelshape = (weight_shape[0] << (4*4)) + (weight_shape[3] << (2*4)) + (weight_shape[1] << (1*4)) + weight_shape[3]
    inputshape = (1 << (4*4)) + (input_shape[2] << (2*4)) + input_shape[0]
    
#     ctrl, outputsize, kernelsize, weightinterval, kernelshape, inputshape, inputrstcnt
#     config = np.array([0, 49283, 0x00010009, 147851, 0x00040333, 0x000103e0, 49727])
#     config = np.array([0, 12320, 0x00120009, 36962, 0x00080333, 0x000103e0, 24863])
#     config = np.array([0, 5475, 0x00130009, 16427, 0x00080333, 0x000103e0, 16575])
    config = np.array([0, outputsize, conf_addr4, weightinterval, kernelshape, inputshape, inputrstcnt])
    regfile = reg.array[0:7]
    
    
    reg.write(0, 2) # reset
    regfile[:] = config
#     reg.write(0, 0) # clear reset
#     reg.write(1 * 4, 49283) # outputsize
#     reg.write(2 * 4, 9) # kernelsize
#     reg.write(3 * 4, 147851) # weightinterval
# #     reg.write(4 * 4, 2097971) # kernelshape
#     reg.write(4 * 4, 0x00080333) # kernelshape 4
# #     reg.write(4 * 4, 0x00200333) # kernelshape 32
#     reg.write(5 * 4, 66528) # inputshape
#     reg.write(6 * 4, 49727) # inputrstcnt
    outputsize = reg.read(1 * 4) # outputsize
    kernelsize = reg.read(2 * 4) # kernelsize
    weightinterval = reg.read(3 * 4) # weightinterval
    kernelshape = reg.read(4 * 4) # kernelshape
    inputshape = reg.read(5 * 4) # inputshape
    inputrstcnt = reg.read(6 * 4) # inputrstcnt
    
    print("Config engine registers")
    print("outputsize    : %d", outputsize)
    print("kernelsize    : %h", hex(kernelsize))
    print("weightinterval: %d", weightinterval)
    print("kernelshape   : %h", hex(kernelshape))
    print("inputshape    : %h", hex(inputshape))
    print("inputrstcnt   : %d", inputrstcnt)
    print()
    print("Start engine")
    
#     print("Transfer output to PS before start")
#     output_buffer = allocate(shape=(222,222,4), dtype=np.uint8)
#     output_size = 222 * 222 * 4
#     transfer(cdma, CDMA_BRAM_OUTPUT_ADDRESS, output_buffer.physical_address, output_size)
#     print(output_buffer[0])
        
    start_time2 = time.time()
    
    reg.write(0, 1) # start engine
    print("Start control: ", reg.read(0))
    status = reg.read(7 * 4)
    print(status)
    while (status == 0):
        status = reg.read(7 * 4)
        
    print(status)

    end_time_load2 = time.time()
    
    print("Done")
    print()
    print("=== Dbg Status ===")
    
    dbg_datareq_knlinex_cnt = reg.read(8 * 4)
    dbg_datareq_addr_reg = reg.read(9 * 4)
    dbg_linekcpe_valid_knx_cnt = reg.read(10 * 4)
    dbg_linekcpe_psum_line_vld_cnt = reg.read(11 * 4)
    dbg_linekcpe_idata_req_cnt = reg.read(12 * 4)
    dbg_linekcpe_odata_req_cnt = reg.read(13 * 4)
    dbg_linekcpe_weight_line_req_cnt = reg.read(14 * 4)
    dbg_linekcpe_weight_done_cnt = reg.read(15 * 4)
    dbg_linekcpe_kernel_done_cnt = reg.read(16 * 4)
    dbg_psumacc_base_addr = reg.read(17 * 4)
    dbg_psumacc_psum_out_cnt = reg.read(18 * 4)
    dbg_psumacc_rd_addr = reg.read(19 * 4)
    dbg_psumacc_wr_addr = reg.read(20 * 4)
    
    print("dbg_datareq_knlinex_cnt         : ", dbg_datareq_knlinex_cnt)
    print("dbg_datareq_addr_reg            : ", dbg_datareq_addr_reg)
    print()
    print("dbg_linekcpe_valid_knx_cnt      : ", dbg_linekcpe_valid_knx_cnt)
    print("dbg_linekcpe_psum_line_vld_cnt  : ", dbg_linekcpe_psum_line_vld_cnt)
    print("dbg_linekcpe_idata_req_cnt      : ", dbg_linekcpe_idata_req_cnt)
    print("dbg_linekcpe_odata_req_cnt      : ", dbg_linekcpe_odata_req_cnt)
    print("dbg_linekcpe_weight_line_req_cnt: ", dbg_linekcpe_weight_line_req_cnt)
    print("dbg_linekcpe_weight_done_cnt    : ", dbg_linekcpe_weight_done_cnt)
    print("dbg_linekcpe_kernel_done_cnt    : ", dbg_linekcpe_kernel_done_cnt)
    print()
    print("dbg_psumacc_base_addr           : ", dbg_psumacc_base_addr)
    print("dbg_psumacc_psum_out_cnt        : ", dbg_psumacc_psum_out_cnt)
    print("dbg_psumacc_rd_addr             : ", dbg_psumacc_rd_addr)
    print("dbg_psumacc_wr_addr             : ", dbg_psumacc_wr_addr)
    print()
    
    reg.write(0, 4) # allow ps access output memory
#     regfile[0] = 4

    print("Transfer output to PS")
    output_buffer = allocate(shape=(output_width * weight_shape[0]//4, output_width,4), dtype=np.uint8)
#     output_buffer = allocate(shape=(222*4,222,4), dtype=np.uint8)
    output_size = output_width * output_width * 4 * weight_shape[0]//4
#     transfer(cdma, CDMA_BRAM_OUTPUT0_ADDRESS, output_buffer.physical_address, output_size)
    transfer(cdma, CDMA_BRAM_OUTPUT0_ADDRESS, output_buffer.physical_address, 32768*4)
    transfer(cdma, CDMA_BRAM_OUTPUT1_ADDRESS, output_buffer.physical_address + 32768*4, 32768*4)
    transfer(cdma, CDMA_BRAM_OUTPUT2_ADDRESS, output_buffer.physical_address + 2*32768*4, 32768*4)
    transfer(cdma, CDMA_BRAM_OUTPUT3_ADDRESS, output_buffer.physical_address + 3*32768*4, output_size - 3*32768*4)

    end_time2 = time.time()

    if (inputshape == 0x00080333):
    #     reg.write(4 * 4, 0x00100333) # kernelshape 4
        reg.write(0, 17) # continue engine
    #     reg.write(0, 1) # continue engine
    #     regfile[0] = 17
    #     regfile[0] = 1

        status = reg.read(7 * 4)
        print(status)

        while (status == 0):
            status = reg.read(7 * 4)

        print(status)

        end_time3 = time.time()

        reg.write(0, 4) # allow ps access output memory

        print("Transfer output to PS")
        transfer(cdma, CDMA_BRAM_OUTPUT0_ADDRESS, output_buffer.physical_address + output_size, 32768*4)
        transfer(cdma, CDMA_BRAM_OUTPUT1_ADDRESS, output_buffer.physical_address + output_size + 32768*4, 32768*4)
        transfer(cdma, CDMA_BRAM_OUTPUT2_ADDRESS, output_buffer.physical_address + output_size + 2*32768*4, 32768*4)
        transfer(cdma, CDMA_BRAM_OUTPUT3_ADDRESS, output_buffer.physical_address + output_size + 3*32768*4, output_size - 3*32768*4)
    
    print()
    print("=== Dbg Status ===")
    
    dbg_datareq_knlinex_cnt = reg.read(8 * 4)
    dbg_datareq_addr_reg = reg.read(9 * 4)
    dbg_linekcpe_valid_knx_cnt = reg.read(10 * 4)
    dbg_linekcpe_psum_line_vld_cnt = reg.read(11 * 4)
    dbg_linekcpe_idata_req_cnt = reg.read(12 * 4)
    dbg_linekcpe_odata_req_cnt = reg.read(13 * 4)
    dbg_linekcpe_weight_line_req_cnt = reg.read(14 * 4)
    dbg_linekcpe_weight_done_cnt = reg.read(15 * 4)
    dbg_linekcpe_kernel_done_cnt = reg.read(16 * 4)
    dbg_psumacc_base_addr = reg.read(17 * 4)
    dbg_psumacc_psum_out_cnt = reg.read(18 * 4)
    dbg_psumacc_rd_addr = reg.read(19 * 4)
    dbg_psumacc_wr_addr = reg.read(20 * 4)
    
    print("dbg_datareq_knlinex_cnt         : ", dbg_datareq_knlinex_cnt)
    print("dbg_datareq_addr_reg            : ", dbg_datareq_addr_reg)
    print()
    print("dbg_linekcpe_valid_knx_cnt      : ", dbg_linekcpe_valid_knx_cnt)
    print("dbg_linekcpe_psum_line_vld_cnt  : ", dbg_linekcpe_psum_line_vld_cnt)
    print("dbg_linekcpe_idata_req_cnt      : ", dbg_linekcpe_idata_req_cnt)
    print("dbg_linekcpe_odata_req_cnt      : ", dbg_linekcpe_odata_req_cnt)
    print("dbg_linekcpe_weight_line_req_cnt: ", dbg_linekcpe_weight_line_req_cnt)
    print("dbg_linekcpe_weight_done_cnt    : ", dbg_linekcpe_weight_done_cnt)
    print("dbg_linekcpe_kernel_done_cnt    : ", dbg_linekcpe_kernel_done_cnt)
    print()
    print("dbg_psumacc_base_addr           : ", dbg_psumacc_base_addr)
    print("dbg_psumacc_psum_out_cnt        : ", dbg_psumacc_psum_out_cnt)
    print("dbg_psumacc_rd_addr             : ", dbg_psumacc_rd_addr)
    print("dbg_psumacc_wr_addr             : ", dbg_psumacc_wr_addr)
    print()
    
    print("================= Result ==========================")
    print("Reshape                      : %s seconds" % (end_time_load1 - start_time1))
    print("Transfer data and weight time: %s seconds" % (end_time1 - end_time_load0 - (end_time_load1 - start_time1)))
    print()
    
    print("Processing time 1            : %s seconds" % (end_time_load2 - start_time2))
#     print("Processing time 2            : %s seconds" % (end_time3 - end_time2))
#     print("Processing time with overflow: %s seconds" % (end_time3 - start_time2))
    print()
    
    print("Transfer output time         : %s seconds" % (end_time2 - end_time_load2))
    print()
    
    print("Total except load data to DDR: %s s" % (end_time2 - end_time_load0))
    print("Total                        : %s s" % (end_time2 - start_time0))
    
    
#     f = open("output/conv_l1.txt", "w")
#     f.write(np.array2string(output_buffer))
#     f.close()
#     np.savetxt('conv_l1.txt', output_buffer, delimiter=',')
    with open('output/conv_l1.txt', 'w') as outfile:
        for slice_2d in output_buffer:
            np.savetxt(outfile, slice_2d, fmt='% 4d')
    
#     print("Read before config")
#     print(output_buffer_err)
#     print()
#     print("Read after config")
# #     print(output_buffer[55])
    
#     reshaped_output_buffer = allocate(shape=(222,222,4), dtype=np.uint8)
#     reshaped_output_buffer[:] = output_buffer.transpose((1,2,0))
#     print("\nReshape")
#     print(reshaped_output_buffer[0])
    
#     with open('output/conv_l1_reshaped.txt', 'w') as outfile:
#         for slice_2d in reshaped_output_buffer:
#             np.savetxt(outfile, slice_2d, fmt='% 4d')

main()
# tconv2d()