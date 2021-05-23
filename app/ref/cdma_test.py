import numpy as np
from pynq import allocate
from pynq import MMIO
from pynq import Overlay
from enum import IntEnum
import time

overlay = Overlay('./overlay/zynq_cdma_sys/zynq_cdma_sys.bit')

cdma = overlay.axi_cdma_0
input_buffer = allocate(shape=(16384,), dtype=np.uint32)

for i in range(16384):
   input_buffer[i] = i

print("Input:")

for i in range(5):
    print(str(input_buffer[i]) + ", ", end="")

print()

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

print("==== Test CDMA ====")

start_time = time.time()
transfer(cdma, input_buffer.physical_address, 0x80000000, 16384)
end_time = time.time()

print("%s seconds" % (end_time - start_time))
print()

bram0 = overlay.axi_bram_ctrl_1

data = []

for i in range(100):
    dat = bram0.read(4*i)
    data.append(dat)

print(data)
