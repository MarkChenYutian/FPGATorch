#pragma once

#include <cstring>
#include <cstdio>
#include <sys/mman.h>
#include <unistd.h>
#include <fcntl.h>
#include "hwlib.h"
#include "socal/socal.h"
#include "socal/hps.h"
#include "socal/alt_gpio.h"
#include "../MatrixInterface.h"
#include "../hps_0.h"

#define HW_REGS_BASE ( ALT_STM_OFST )
#define HW_REGS_SPAN ( 0x04000000 )
#define H2F_AXI_BASE ( 0xC0000000 )
#define H2F_AXI_SPAN ( 0x00100000 )
#define H2F_AXI_MASK ( H2F_AXI_SPAN - 1 )
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 )
#define NONE (0)
#define MAT_ADD (1)
#define MAT_SCAL_MUL (2)
#define MAT_SCAL_DIV (3)
#define MAT_SCAL_ADD (4)
// #define MAT_SCAL_INV (5)
#define MAT_MUL (6)
// #define MAT_TRAS (7)
// #define REDUCE_SUM (8)

static int fd;
static void *Mat_A_Base;
static void *Mat_B_Base;
static void *Mat_C_Base;
static void *Instruction_Base;

int MMap_Init() {
  void *virtual_base;
  void *fpga_mem_base;
  if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
    printf( "ERROR: could not open \"/dev/mem\"...\n" );
    return( 1 );
  }

  virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );

  if( virtual_base == MAP_FAILED ) {
    printf( "ERROR: mmap() failed...\n" );
    close( fd );
    return( 1 );
  }
  Instruction_Base = virtual_base + ( ( unsigned long )(ALT_LWFPGASLVS_OFST) & ( unsigned long)( HW_REGS_MASK ) );

  fpga_mem_base = mmap( NULL, H2F_AXI_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, H2F_AXI_BASE );

  if( fpga_mem_base == MAP_FAILED ) {
    printf( "ERROR: mmap() failed...\n" );
    close( fd );
    return( 1 );
  }
  Mat_A_Base = fpga_mem_base + ( ( unsigned long )( FPGA_MEM_A_BASE ) & ( unsigned long )( H2F_AXI_MASK ) );
  Mat_B_Base = fpga_mem_base + ( ( unsigned long )( FPGA_MEM_B_BASE ) & ( unsigned long )( H2F_AXI_MASK ) );
  Mat_C_Base = fpga_mem_base + ( ( unsigned long )( FPGA_MEM_C_BASE ) & ( unsigned long )( H2F_AXI_MASK ) );
  return 0;
}

SmartTensor MatMul128x128(const SmartTensor &A, const SmartTensor &B) {
  SmartTensor C = MatNew(A->size[0], A->size[1], B->size[2]);

  memcpy(Mat_A_Base, &(A->data), sizeof(float) * (A->size[1]) * (A->size[2]));
  memcpy(Mat_B_Base, &(B->data), sizeof(float) * (B->size[1]) * (B->size[2]));
  uint32_t Instruction = ((MAT_MUL & 0x000F) << 28) | (((A->size[1]) & 0x007F) << 21) | (((A->size[2]) & 0x007F) << 21) |  (((B->size[1]) & 0x007F) << 14) | ((B->size[2]) & 0x007F);
  *(uint32_t *)Instruction_Base = Instruction;

  while (*(uint32_t *)Instruction_Base != 0x00000000);
  memcpy(&(C->data), Mat_C_Base, sizeof(float) * (A->size[1]) * (B->size[2]));

  return C;
}

void MatScalarMul128x128(float *A, float scalar, float *result, size_t count) {
  memcpy(Mat_A_Base, &A, sizeof(float) * count);
  memcpy(Instruction_Base, &scalar, sizeof(float));
  uint32_t Instruction = ((MAT_SCAL_MUL & 0x000F) << 28) | ((count & 0x3FFF) << 14); // todo: change fpga memory representation
  *(uint32_t *) Instruction_Base = Instruction;

  while (*(uint32_t *) Instruction_Base != 0x00000000);
  memcpy(&result, Mat_C_Base, sizeof(float) * count);
}

void MatScalarDiv128x128(float *A, float scalar, float *result, size_t count) {
  memcpy(Mat_A_Base, &A, sizeof(float) * count);
  memcpy(Instruction_Base, &scalar, sizeof(float));
  uint32_t Instruction = ((MAT_SCAL_DIV & 0x000F) << 28) | ((count & 0x003F) << 21); // todo: change fpga memory representation
  *(uint32_t *) Instruction_Base = Instruction;

  while (*(uint32_t *) Instruction_Base != 0x00000000);
  memcpy(&result, Mat_C_Base, sizeof(float) * count);
}

void MatScalarAdd128x128(float *A, float scalar, float *result, size_t count) {
  memcpy(Mat_A_Base, &A, sizeof(float) * count);
  memcpy(Instruction_Base, &scalar, sizeof(float));
  uint32_t Instruction = ((MAT_SCAL_ADD & 0x000F) << 28) | ((count & 0x003F) << 21); // todo: change fpga memory representation
  *(uint32_t *) Instruction_Base = Instruction;

  while (*(uint32_t *) Instruction_Base != 0x00000000);
  memcpy(&result, Mat_C_Base, sizeof(float) * count);
}

void MatScalarInv128x128(float *A, float *result, size_t count) {
  memcpy(Mat_A_Base, &A, sizeof(float) * count);
  uint32_t Instruction = ((MAT_SCAL_MUL & 0x000F) << 28) | ((count & 0x003F) << 21); // todo: change fpga memory representation
  *(uint32_t *) Instruction_Base = Instruction;

  while (*(uint32_t *) Instruction_Base != 0x00000000);
  memcpy(&result, Mat_C_Base, sizeof(float) * count);
}

void MatElementwiseMul128x128(float *A, float *B, float *Result, size_t count) {
  memcpy(Mat_A_Base, &A, sizeof(float) * count);
  memcpy(Mat_B_Base, &B, sizeof(float) * count);
  uint32_t Instruction = ((MAT_ELE_MUL & 0x000F) << 28) | ((count & 0x003F) << 21); // todo: change fpga memory representation
  *(uint32_t *) Instruction_Base = Instruction;

  while (*(uint32_t *) Instruction_Base != 0x00000000);
  memcpy(&Result, Mat_C_Base, sizeof(float) * count);
}

void MatAdd128x128(float *A, float *B, float *Result, size_t count) {
  memcpy(Mat_A_Base, &A, sizeof(float) * count);
  memcpy(Mat_B_Base, &B, sizeof(float) * count);
  uint32_t Instruction = ((MAT_ADD & 0x000F) << 28) | ((count & 0x003F) << 21); // todo: change fpga memory representation
  *(uint32_t *) Instruction_Base = Instruction;

  while (*(uint32_t *) Instruction_Base != 0x00000000);
  memcpy(&Result, Mat_C_Base, sizeof(float) * count);
}

