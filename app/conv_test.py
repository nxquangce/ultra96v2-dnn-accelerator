from pynq import Overlay
from pynq import allocate
from pynq import MMIO
from enum import IntEnum
from PIL import Image
import numpy as np
import tflite_runtime.interpreter as tflite

import torch

import time

overlay_name = "zynqmpsoc_conv_dbg_20210708_2319"

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

def indirect_read(reg, addr):
    reg.write(8 * 4, addr)
    data = reg.read(11 * 4)
    return data
    
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
    stride = 2
    padding = 1
    
    output_width = (input_shape[0] - weight_shape[1] + padding) // stride + 1
    output_shape = [output_width, output_width, weight_shape[0]]
    
    minrow = 0 if (padding == 0) else 1
    inputrstcnt = (output_width - minrow) * input_shape[0] - 1
    num_invalid_row = input_shape[0] + padding - output_width * stride - 1
    num_invalid_row = 1

    outputsize = output_width * output_width - 1
    conf_addr3 = (padding << (6*4)) + (num_invalid_row << (5*4)) + (stride << (4*4)) + weight_shape[1]**2
    weightinterval = output_width ** 2 * 3 - 1

    inputshape = (1 << (4*4)) + (input_shape[2] << (2*4)) + input_shape[0]
    kernelshape = (weight_shape[0] << (4*4)) + (weight_shape[3] << (2*4)) + (weight_shape[1] << (1*4)) + weight_shape[3]
    outputshape = (weight_shape[0] << (2*4)) + (output_width)
    
#     ctrl, inputshape, kernelshape, kernelsize, outputshape, outputsize, weightinterval, inputrstcnt
#     config = np.array([2, 0x000103e0, 0x00040333, 0x00010009, 0x000008de, 49283, 147851, 49727])
#     config = np.array([2, 0x000103e0, 0x00080333, 0x00120009, 0x0000086f, 12320, 36962, 0x00080333, 24863])
#     config = np.array([2, 0x000103e0, 0x00080333, 0x00130009, 0x0000084a, 5475, 16427, 0x00080333, 0x000103e0, 16575])
    config = np.array([2, inputshape, kernelshape, conf_addr3, outputshape, outputsize, weightinterval, inputrstcnt])
#     config = np.array([2, 50175, 0x02110009, 150527, kernelshape, inputshape, 49951])
    regfile = reg.array[0:8]
    
    
#     reg.write(0, 2) # reset
    regfile[:] = config
    inputshape = reg.read(1 * 4)
    kernelshape = reg.read(2 * 4)
    kernelsize = reg.read(3 * 4)
    outputshape = reg.read(4 * 4)
    outputsize = reg.read(5 * 4)
    weightinterval = reg.read(6 * 4)
    inputrstcnt = reg.read(7 * 4)
    
    print("Config engine registers")
    print("inputshape    : %h", "0x{:08x}".format(inputshape))
    print("kernelshape   : %h", "0x{:08x}".format(kernelshape))
    print("kernelsize    : %h", "0x{:08x}".format(kernelsize))
    print("outputshape   : %d", "0x{:08x}".format(outputshape))
    print("outputsize    : %d", outputsize)
    print("weightinterval: %d", weightinterval)
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
    status = reg.read(10 * 4)
    print(status)
    while (status == 0):
        status = reg.read(10 * 4)
        
    print(status)

    end_time_load2 = time.time()
    
    print("Done")
    print()
    print("=== Dbg Status ===")
    
    dbg_datareq_addr_reg = indirect_read(reg, 0xf0000000)
    dbg_datareq_knlinex_cnt = indirect_read(reg, 0xf0000001)
    dbg_psumacc_rd_addr = indirect_read(reg, 0xf0000002)
    dbg_psumacc_wr_addr = indirect_read(reg, 0xf0000003)
    dbg_psumacc_psum_out_cnt = indirect_read(reg, 0xf0000004)
    dbg_psumacc_base_addr = indirect_read(reg, 0xf0000005)
    dbg_linekcpe_kernel_done_cnt = indirect_read(reg, 0xf0000006)
    dbg_linekcpe_weight_done_cnt = indirect_read(reg, 0xf0000007)
    dbg_linekcpe_weight_line_req_cnt = indirect_read(reg, 0xf0000008)
    dbg_linekcpe_odata_req_cnt = indirect_read(reg, 0xf0000009)
    dbg_linekcpe_idata_req_cnt = indirect_read(reg, 0xf000000a)
    dbg_linekcpe_psum_line_vld_cnt = indirect_read(reg, 0xf000000b)
    dbg_linekcpe_valid_knx_cnt = indirect_read(reg, 0xf000000c)
    
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

    print("Transfer output to PS 0")
    output_buffer = allocate(shape=(output_width * weight_shape[0]//4, output_width,4), dtype=np.uint8)
#     output_buffer = allocate(shape=(222*4,222,4), dtype=np.uint8)
    output_size = output_width * output_width * 4 * weight_shape[0]//4
#     transfer(cdma, CDMA_BRAM_OUTPUT0_ADDRESS, output_buffer.physical_address, output_size)

    transfer(cdma, CDMA_BRAM_OUTPUT0_ADDRESS, output_buffer.physical_address, 32768*4)
    transfer(cdma, CDMA_BRAM_OUTPUT1_ADDRESS, output_buffer.physical_address + 32768*4, 32768*4)
    transfer(cdma, CDMA_BRAM_OUTPUT2_ADDRESS, output_buffer.physical_address + 2*32768*4, 32768*4)
    transfer(cdma, CDMA_BRAM_OUTPUT3_ADDRESS, output_buffer.physical_address + 3*32768*4, output_size - 3*32768*4)

    end_time2 = time.time()

    conf_conenb = False
    if (conf_conenb):
    #     reg.write(4 * 4, 0x00100333) # kernelshape 4
        reg.write(0, 17) # continue engine
    #     reg.write(0, 1) # continue engine
    #     regfile[0] = 17
    #     regfile[0] = 1

        status = reg.read(9 * 4)
        print(status)

        while (status == 0):
            status = reg.read(9 * 4)

        print(status)

        end_time3 = time.time()

        reg.write(0, 4) # allow ps access output memory

        print("Transfer output to PS 1")
        transfer(cdma, CDMA_BRAM_OUTPUT0_ADDRESS, output_buffer.physical_address + output_size, 32768*4)
        transfer(cdma, CDMA_BRAM_OUTPUT1_ADDRESS, output_buffer.physical_address + output_size + 32768*4, 32768*4)
        transfer(cdma, CDMA_BRAM_OUTPUT2_ADDRESS, output_buffer.physical_address + output_size + 2*32768*4, 32768*4)
        transfer(cdma, CDMA_BRAM_OUTPUT3_ADDRESS, output_buffer.physical_address + output_size + 3*32768*4, output_size - 3*32768*4)
    
        print()
        print("=== Dbg Status ===")

        dbg_datareq_addr_reg = indirect_read(reg, 0xf0000000)
        dbg_datareq_knlinex_cnt = indirect_read(reg, 0xf0000001)
        dbg_psumacc_rd_addr = indirect_read(reg, 0xf0000002)
        dbg_psumacc_wr_addr = indirect_read(reg, 0xf0000003)
        dbg_psumacc_psum_out_cnt = indirect_read(reg, 0xf0000004)
        dbg_psumacc_base_addr = indirect_read(reg, 0xf0000005)
        dbg_linekcpe_kernel_done_cnt = indirect_read(reg, 0xf0000006)
        dbg_linekcpe_weight_done_cnt = indirect_read(reg, 0xf0000007)
        dbg_linekcpe_weight_line_req_cnt = indirect_read(reg, 0xf0000008)
        dbg_linekcpe_odata_req_cnt = indirect_read(reg, 0xf0000009)
        dbg_linekcpe_idata_req_cnt = indirect_read(reg, 0xf000000a)
        dbg_linekcpe_psum_line_vld_cnt = indirect_read(reg, 0xf000000b)
        dbg_linekcpe_valid_knx_cnt = indirect_read(reg, 0xf000000c)

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
    
    
    time_cycle = indirect_read(reg, 0xf0000010)
    print("time = ", time_cycle, " x 1/299e6 = ", time_cycle/299999999, " s")
    
    
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