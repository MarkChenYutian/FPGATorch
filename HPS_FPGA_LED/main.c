/*
This program demonstrate how to use hps communicate with FPGA through light AXI Bridge.
uses should program the FPGA by GHRD project before executing the program
refer to user manual chapter 7 for details about the demo
*/


#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
#include "hwlib.h"
#include "socal/socal.h"
#include "socal/hps.h"
#include "socal/alt_gpio.h"
#include "hps_0.h"

#define HW_REGS_BASE ( ALT_STM_OFST )
#define HW_REGS_SPAN ( 0x04000000 )
#define H2F_AXI_BASE ( 0xC0000000 )
#define H2F_AXI_SPAN ( 0x00100000 )
#define H2F_AXI_MASK (H2F_AXI_SPAN - 1 )
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 )

int main() {
	void *instruction_base;
	void *fpga_mem_base;
	int loop_count;
	int led_direction;
	int led_mask;
	void *h2p_lw_led_addr;
	void *Mat_A_Base;
	void *Mat_B_Base;
	void *Mat_C_Base;
	uint32_t Instruction;

	// map the address space for the LED registers into user space so we can interact with them.
	// we'll actually map in the entire CSR span of the HPS since we want to access various registers within that span

	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return( 1 );
	}

	// h2f_lw_axi_bridge
	instruction_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );
	
	if( instruction_base == MAP_FAILED ) {
		printf( "ERROR: mmap() failed...\n" );
		close( fd );
		return( 1 );
	}
	h2p_lw_led_addr = instruction_base + ( ( unsigned long )( ALT_LWFPGASLVS_OFST + LED_PIO_BASE ) & ( unsigned long)( HW_REGS_MASK ) );

	// h2f_axi_bridge
	fpga_mem_base = mmap( NULL, FPGA_MEM_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, H2F_AXI_BASE );

	if( fpga_mem_base == MAP_FAILED ) {
		printf( "ERROR: mmap() failed...\n" );
		close( fd );
		return( 1 );
	}
	Mat_A_Base = fpga_mem_base + ( ( unsigned long )( FPGA_MEM_A_BASE ) & ( unsigned long )( H2F_AXI_MASK ) );
	Mat_B_Base = fpga_mem_base + ( ( unsigned long )( FPGA_MEM_B_BASE ) & ( unsigned long )( H2F_AXI_MASK ) );
	Mat_C_Base = fpga_mem_base + ( ( unsigned long )( FPGA_MEM_C_BASE ) & ( unsigned long )( H2F_AXI_MASK ) );

	Instruction = ((0x4 & 0x000F) << 28) | ((0x2 & 0x003F) << 21) | ((0x2 & 0x003F) << 14) | 0x0000;
	// toggle the LEDs a bit
	float mat_a[] = {1.0, 2.0, 3.0, 4.0};
	float scalar = 2.0;
	memcpy(Mat_A_Base, &mat_a, sizeof(float) * 4);
	memcpy(Mat_B_Base, &scalar, sizeof(float));
	*(uint32_t *)instruction_base = Instruction;
	while ( *(uint32_t *)instruction_base != 0x0000u) {
		usleep( 1*1000 );
	}
	float mat_res[4];
	memcpy(&mat_res, Mat_C_Base, sizeof(float) * 4);

	for (int i = 0; i < 4; i++) {
		printf("%f\n", mat_res[i]);
	}
	
	// loop_count = 0;
	// led_mask = 0x01;
	// led_direction = 0; // 0: left to right direction
	// while( loop_count < 5 ) {
		
	// 	// control led
	// 	*(uint32_t *)h2p_lw_led_addr = ~led_mask; 

	// 	// wait 100ms
	// 	usleep( 100*1000 );
		
	// 	// update led mask
	// 	if (led_direction == 0){
	// 		led_mask <<= 1;
	// 		if (led_mask == (0x01 << (LED_PIO_DATA_WIDTH-1)))
	// 			 led_direction = 1;
	// 	}else{
	// 		led_mask >>= 1;
	// 		if (led_mask == 0x01){ 
	// 			led_direction = 0;
	// 			loop_count++;
	// 		}
	// 	}
	// } // while
	
	// clean up our memory mapping and exit
	
	if( munmap( instruction_base, HW_REGS_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close( fd );
		return( 1 );
	}
	if( munmap( fpga_mem_base, FPGA_MEM_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close( fd );
		return( 1 );
	}

	close( fd );
	return( 0 );
}
