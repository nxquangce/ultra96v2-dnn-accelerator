from pynq import Overlay
from pynq import allocate
from pynq import MMIO
from PIL import Image
import driver
import numpy as np
import tflite_runtime.interpreter as tflite
import torch
import time

overlay_name = "zynqmpsoc_conv_dbg_20210731_1222"
app_version = "dev.582a3ccb.1"

print("+---------------------------------------+")
print("| Welcome to hardware accelerator demo. |")
print("+---------------------------------------+")
print("|    App version   : " + app_version + "     |")
print("|    Driver version: " + driver.version + "     |")
print("+---------------------------------------+")
print()
print("Config hardware...")
print("Harware version: " + overlay_name)
print()

overlay = Overlay('./overlay/dnn/' +  overlay_name + '.bit')
model_file = './models/mobilenet_v1_1.0_224_quant.tflite'
cdma = driver.Cdma(overlay)
reg = driver.Register(overlay)

def load_weight():
    interpreter = tflite.Interpreter(model_path=model_file)
    interpreter.allocate_tensors()
    
    weight_l1 = interpreter.get_tensor(8)
    return weight_l1

def load_input():
    image = Image.open("input224.jpg")
    data = np.array(image)
    input_data = np.expand_dims(data, 0)  # shape (1, y_pixels, x_pixels, n_bands)
    return input_data

def t_weight(weight_data, num_of_kernel):
    weight_l1_0_3 = weight_data[0:num_of_kernel]
    t_weight_l1_0_3 = torch.from_numpy(weight_l1_0_3)
    t_weight_l1_0_3 = np.transpose(t_weight_l1_0_3, (0, 3, 1, 2))
    return t_weight_l1_0_3
    
def t_input(input_data):
    input_data_transpose = np.transpose(input_data, (0, 3, 1, 2))
    t_input_data = torch.from_numpy(input_data_transpose)
    return t_input_data
    

def t_conv2d(t_input_data, t_weight_data, stride, pad):
    padding = 0
    if (pad > 0):
        padding = 1
    print("Perform PS Conv...", end="")
    t_output = torch.nn.functional.conv2d(t_input_data, t_weight_data, bias=None, stride=stride, padding=padding) #, dilation=1, groups=1)
    print("Done.")
    return t_output

def hw_input(input_data, input_shape):
    input_buffer = allocate(shape=(input_shape[0],input_shape[1],input_shape[2]), dtype=np.uint8)
    input_buffer[:] = input_data
    input_size = input_shape[0]*input_shape[1]*input_shape[2]
    cdma.transfer(input_buffer.physical_address, driver.CDMA_BRAM_INPUT_ADDRESS, input_size)
    
def hw_weight(weight_data):
    weight_l1 = weight_data
    weight_l1_0 = np.concatenate((weight_l1[0], weight_l1[4], weight_l1[8], weight_l1[12], weight_l1[16], weight_l1[20], weight_l1[24], weight_l1[28]))
    weight_l1_0_buffer = allocate(shape=(24,3,3), dtype=np.uint8)
    weight_l1_0_buffer[:] = weight_l1_0
    
    weight_l1_1 = np.concatenate((weight_l1[1], weight_l1[5], weight_l1[9], weight_l1[13], weight_l1[17], weight_l1[21], weight_l1[25], weight_l1[29]))
    weight_l1_1_buffer = allocate(shape=(24,3,3), dtype=np.uint8)
    weight_l1_1_buffer[:] = weight_l1_1
    
    weight_l1_2 = np.concatenate((weight_l1[2], weight_l1[6], weight_l1[10], weight_l1[14], weight_l1[18], weight_l1[22], weight_l1[26], weight_l1[30]))
    weight_l1_2_buffer = allocate(shape=(24,3,3), dtype=np.uint8)
    weight_l1_2_buffer[:] = weight_l1_2
    
    weight_l1_3 = np.concatenate((weight_l1[3], weight_l1[7], weight_l1[11], weight_l1[15], weight_l1[19], weight_l1[23], weight_l1[27], weight_l1[31]))
    weight_l1_3_buffer = allocate(shape=(24,3,3), dtype=np.uint8)
    weight_l1_3_buffer[:] = weight_l1_3
    
    weight_size = 3*3*3*8
    cdma.transfer(weight_l1_0_buffer.physical_address, driver.CDMA_BRAM_WEIGHT0_ADDRESS, weight_size)
    cdma.transfer(weight_l1_1_buffer.physical_address, driver.CDMA_BRAM_WEIGHT1_ADDRESS, weight_size)
    cdma.transfer(weight_l1_2_buffer.physical_address, driver.CDMA_BRAM_WEIGHT2_ADDRESS, weight_size)
    cdma.transfer(weight_l1_3_buffer.physical_address, driver.CDMA_BRAM_WEIGHT3_ADDRESS, weight_size)
    
def hw_config(input_shape, weight_shape, stride, padding):
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
#     config = np.array([2, 0x000103e0, 0x00080333, 0x00120009, 0x0000086f, 12320, 36962, 24863])
#     config = np.array([2, 0x000103e0, 0x00080333, 0x00130009, 0x0000084a, 5475, 16427, 0x00080333, 0x000103e0, 16575])
    config = np.array([2, inputshape, kernelshape, conf_addr3, outputshape, outputsize, weightinterval, inputrstcnt])
#     config = np.array([2, 50175, 0x02110009, 150527, kernelshape, inputshape, 49951])
    regfile = reg.reg.array[0:8]
    
    
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
    print("outputshape   : %h", "0x{:08x}".format(outputshape))
    print("outputsize    : %d", outputsize)
    print("weightinterval: %d", weightinterval)
    print("inputrstcnt   : %d", inputrstcnt)
    print()
    return output_shape

def hw_conv2d(output_width, weight_shape):
    print("Perform PL Conv...", end="")
    reg.write(0, 1) # start engine
    status = reg.read(10 * 4)
    while (status == 0):
        status = reg.read(10 * 4)
    print("Done.")
    
def hw_read_output(output_width, weight_shape):
    print("Transfer output to PS 0")
    reg.write(0, 4) # allow ps access output memory
#     regfile[0] = 4

    output_buffer = allocate(shape=(output_width * weight_shape[0]//4, output_width,4), dtype=np.uint8)
    output_size = output_width * output_width * 4 * weight_shape[0]//4
    
    read_size = output_size
    i = 0
    SIZE_OF_SINGLE_OUTPUT_BRAM = 32768 * 4 # 128 KB
    output_bram_addr = [
        driver.CDMA_BRAM_OUTPUT0_ADDRESS,
        driver.CDMA_BRAM_OUTPUT1_ADDRESS,
        driver.CDMA_BRAM_OUTPUT2_ADDRESS,
        driver.CDMA_BRAM_OUTPUT3_ADDRESS
    ]
    if (output_size <= SIZE_OF_SINGLE_OUTPUT_BRAM):
        cdma.transfer(driver.CDMA_BRAM_OUTPUT0_ADDRESS, output_buffer.physical_address, output_size)
    else:
        while (read_size > SIZE_OF_SINGLE_OUTPUT_BRAM):
            cdma.transfer(output_bram_addr[i], output_buffer.physical_address + SIZE_OF_SINGLE_OUTPUT_BRAM * i, SIZE_OF_SINGLE_OUTPUT_BRAM)
            read_size = read_size - SIZE_OF_SINGLE_OUTPUT_BRAM
            i = i + 1
        cdma.transfer(output_bram_addr[i], output_buffer.physical_address + SIZE_OF_SINGLE_OUTPUT_BRAM * i, read_size)

    return output_buffer

    conf_conenb = False
    if (conf_conenb):
    #     reg.write(4 * 4, 0x00100333) # kernelshape 4
        reg.write(0, 17) # continue engine
    #     reg.write(0, 1) # continue engine
    #     regfile[0] = 17
    #     regfile[0] = 1

        status = reg.read(9 * 4)

        while (status == 0):
            status = reg.read(9 * 4)

        reg.write(0, 4) # allow ps access output memory

        print("Transfer output to PS 1")
        transfer(cdma, CDMA_BRAM_OUTPUT0_ADDRESS, output_buffer.physical_address + output_size, 32768*4)
        transfer(cdma, CDMA_BRAM_OUTPUT1_ADDRESS, output_buffer.physical_address + output_size + 32768*4, 32768*4)
        transfer(cdma, CDMA_BRAM_OUTPUT2_ADDRESS, output_buffer.physical_address + output_size + 2*32768*4, 32768*4)
        transfer(cdma, CDMA_BRAM_OUTPUT3_ADDRESS, output_buffer.physical_address + output_size + 3*32768*4, output_size - 3*32768*4)
    
        print()

def t_write(file_name, t_output_data):
    with open('output/' + file_name, 'w') as outfile:
        for slice_3d in t_output_data:
            for slice_2d in slice_3d:
                np.savetxt(outfile, slice_2d, fmt='% 4d')
        
def hw_write(file_name, output_buffer):
    with open('output/' + file_name, 'w') as outfile:
        for slice_2d in output_buffer:
            np.savetxt(outfile, slice_2d, fmt='% 4d')

def main():
    input_shape = [224, 224, 3]
    weight_shape = [8, 3, 3, 3]
    stride = 1
    padding = 2
    output_shape = None
    input_data = None
    weight_data = None
    t_input_data = None
    t_weight_data = None
    t_output_data = None
    hw_output = None
    
    is_hw_load = False
    
    print("Type 'help' for instructions")
    print()

    cmd = input(">> ")
    while (cmd != "exit"):
        if (cmd == "load"):
            weight_data = load_weight()
            input_data = load_input()
            num_of_kernel = int(input("Enter num of kernel: "))
            stride = int(input("Enter stride : "))
            padding = int(input("Enter padding: "))
            t_input_data = t_input(input_data)
            t_weight_data = t_weight(weight_data, num_of_kernel)
        
        elif (cmd == "hw_load"):
            hw_weight_data = hw_weight(weight_data)
            hw_input_data = hw_input(input_data, [224, 224, 3])
            output_shape = hw_config(input_shape, weight_shape, stride, padding)
            is_hw_load = True
        
        elif (cmd == "ps_conv"):
            t_conv_start = time.time()
            t_output_data = t_conv2d(t_input_data, t_weight_data, stride, padding)
            t_conv_end = time.time()
            print("Execution time on PS: %s s" % (t_conv_end - t_conv_start))

        elif (cmd == "pl_conv"):
            if (is_hw_load):
                hw_conv_start = time.time()
                hw_conv2d(output_shape[0], weight_shape)
                hw_conv_end = time.time()
                hw_output = hw_read_output(output_shape[0], weight_shape)
                hw_read_end = time.time()
                print("Execution time on PL: %s s" % (hw_conv_end - hw_conv_start))
                print("Transfer output time: %s s" % (hw_read_end - hw_conv_end))
            else:
                print("[Error] hw_load must be executed first")

        elif (cmd == "pl_reset"):
            print("Reset Engine")
            cdma.reset()
            reg.write(0, 2)
            
        elif (cmd == "save"):
            print("Writing outputs to files...")
            t_write("torch_output.txt", np.transpose(t_output_data, (0, 2, 3, 1)))
            hw_write("hw_output.txt", hw_output)

        elif (cmd == "help"):
            print(" load    : load model and data from microSD card")
            print(" hw_load : load model and data to accelerate system")
            print(" ps_conv : perform conv2d in software only with pytorch")
            print(" pl_conv : perform conv2d offload with accelerate system")
            print(" pl_reset: soft reset CDMA and engine")
            print(" save    : write conv2d outputs of 2 cases to 2 files")
            print(" exit    : exit program")
        else:
            print("Invalid command")

        print()
        cmd = input(">> ")

main()