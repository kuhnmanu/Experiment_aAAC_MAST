// D128ProxyExample.cpp : Defines the entry point for the console application.
//

// Modified to use C++11 integer types instead of INT32 (doesn't seem to work with MinGW)

#ifndef _D128RPROXY_H
#define _D128RPROXY_H

int __stdcall DGD128_Set(
	long int Mode,
	long int Polarity,
	long int Source,
	long int Demand,
	long int PulseWidth,
	long int Dwell,
	long int Recovery,
	long int Enabled);

int __stdcall DGD128_Get(
	long int * Mode,  
	long int * Polarity,
	long int * Source,
	long int * Demand,
	long int * PulseWidth,
	long int * Dwell,
	long int * Recovery,
	long int * Enabled);

int __stdcall DGD128_Trigger();

#endif
