#!/bin/bash
echo "assembling..."
rgbasm -L -o test_joypad.o test_joypad.gameboy.asm
echo "linking..."
rgblink -o test_joypad.gb test_joypad.o
echo "fixing..."
rgbfix -v -p 0xFF test_joypad.gb
echo "linking symbols..."
rgblink -n test_joypad.sym test_joypad.o
echo "done"