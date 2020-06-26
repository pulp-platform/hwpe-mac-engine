#!/usr/bin/env python3
#
# uloop_check.py
# Francesco Conti <fconti@iis.ee.ethz.ch>
#
# Copyright (C) 2018-2019 ETH Zurich, University of Bologna
# Copyright and related rights are licensed under the Solderpad Hardware
# License, Version 0.51 (the "License"); you may not use this file except in
# compliance with the License.  You may obtain a copy of the License at
# http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
# or agreed to in writing, software, hardware and materials distributed under
# this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#

from __future__ import print_function
from uloop_common import *

# Sets the overall number of loops activated in the microcode (max. 6 nested loops)
NB_LOOPS = 1

# high-level loop
def iterate_hl_loop(nb_iter, iter_stride, one_stride):
    a_idx = 0 
    b_idx = 0 
    c_idx = 0 
    d_idx = 0 
    curr_idx = (0,)
    for i in range(0, nb_iter-1):
        a_idx = a_idx + iter_stride
        b_idx = b_idx + iter_stride
        c_idx = c_idx + one_stride
        d_idx = d_idx + one_stride
        curr_idx = i,
        yield a_idx, b_idx, c_idx, d_idx, curr_idx

VERBOSE = True

def uloop_check(nb_iter, iter_stride, one_stride, verbose=VERBOSE):

    print("> Config nb_iter=%d, iter_stride=%d, one_stride=%d" % (nb_iter, iter_stride, one_stride))

    loops_range = [
        nb_iter,
    ]

    registers = [
        0,
        0,
        0,
        0,
        nb_iter,
        iter_stride,
        one_stride,
    ]

    loops_ops,code,mnem = uloop_load("code.yml")
    loops = uloop_get_loops(loops_ops, loops_range)

    err = 0
    idx  = []
    for j in range(NB_LOOPS):
        idx.append(0)
    state = (0,0,0,idx)
    busy = False
    execute = True
    # uloop_print_idx(state, registers)
    hidx = 0, 0, 0, 0, 0, 0
    hl_loop = iterate_hl_loop(nb_iter, iter_stride, one_stride)
    for i in range(0,1000):
        new_registers = uloop_execute(state, code, registers)
        execute,end,busy,state = uloop_state_machine(loops, state, verbose=verbose, nb_loops=NB_LOOPS)
        if execute:
            registers = new_registers
        if not busy:
            try:
                ha, hb, hc, hd, hidx = next(hl_loop)
            except StopIteration:
                pass
            if verbose:
                uloop_print_idx(state, registers)
            ua, ub, uc, ud = registers[0:4]
            if (ha != ua or hb != ub or hc != uc or hd != ud):
                if verbose:
                    print("  ERROR!!!")
                    print("  High-level: a=%d b=%d c=%d d=%d" % (ha, hb, hc, hd))
                    print("  uLoop:      a=%d b=%d c=%d d=%d" % (ua, ub, uc, ud))
                err += 1
        if end:
            break

    print(err, " errors", "!!!" if err > 0 else "")
    return err

for nb_iter in (16,32,64,):
    for iter_stride in (1,16,32,):
        one_stride = 1
        err = uloop_check(nb_iter, iter_stride, one_stride, verbose=False)
        if err>0:
            break
    if err>0:
        break
if err>0:
    err = uloop_check(nb_iter, iter_stride, one_stride, verbose=True)

