/*
 * Copyright (c) 1999 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * Copyright (c) 1999 Apple Computer, Inc.  All Rights Reserved.
 * The contents of this file constitute Original Code as defined in and are 
 * subject to the Apple Public Source License Version 1.1 (the "License").  
 * You may not use this file except in compliance with the License.  Please 
 * obtain a copy of the License at http://www.apple.com/publicsource and 
 * read it before using this file.
 * 
 * This Original Code and all software distributed under the License are 
 * distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, EITHER 
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES, 
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY, FITNESS 
 * FOR A PARTICULAR PURPOSE OR NON-INFRINGEMENT.  Please see the License for 
 * the specific language governing rights and limitations under the 
 * License.
 * 
 * 
 * @APPLE_LICENSE_HEADER_END@
 */
/*
	File:		RTCPSRPacket.h

	Contains:	A class that writes a RTCP Sender Report
				
	Change History (most recent first):

	
*/

#ifndef __RTCP_SR_PACKET__
#define __RTCP_SR_PACKET__

#include "OSHeaders.h"
#include "OS.h"
#include "MyAssert.h"

#ifndef __Win32__
#include <netinet/in.h> //definition of htonl
#endif

class RTCPSRPacket
{
	public:
	
		enum
		{
			kSRPacketType = 200,	//UInt32
			kByePacketType = 203
		};

		RTCPSRPacket();
		~RTCPSRPacket() {}
		
		// ACCESSORS
		
		void*	GetSRPacket() 		{ return &fSenderReportBuffer[0]; }
		UInt32	GetSRPacketLen() 	{ return fSenderReportSize; }
		UInt32	GetSRWithByePacketLen() { return fSenderReportSize + kByeSizeInBytes; }
		
		//
		// MODIFIERS
		
		inline void	SetSSRC(UInt32 inSSRC);

		inline void	SetNTPTimestamp(SInt64 inNTPTimestamp);
		inline void	SetRTPTimestamp(UInt32 inRTPTimestamp);
		
		inline void	SetPacketCount(UInt32 inPacketCount);
		inline void	SetByteCount(UInt32 inByteCount);

		//RTCP support requires generating unique CNames for each session.
		//This function generates a proper cName and returns its length. The buffer
		//passed in must be at least kMaxCNameLen
		enum
		{
			kMaxCNameLen = 60	//Uint32
		};
		static UInt32			GetACName(char* ioCNameBuffer);

	private:
	
		enum
		{
			kSenderReportSizeInBytes = 36,
			kByeSizeInBytes = 8
		};
		char		fSenderReportBuffer[kSenderReportSizeInBytes + kMaxCNameLen + kByeSizeInBytes];
		UInt32		fSenderReportSize;

};

inline void	RTCPSRPacket::SetSSRC(UInt32 inSSRC)
{
	// Set SSRC in SR
	((UInt32*)&fSenderReportBuffer)[1] = htonl(inSSRC);
	
	// Set SSRC in SDES
	((UInt32*)&fSenderReportBuffer)[8] = htonl(inSSRC);
	
	// Set SSRC in BYE
	Assert((fSenderReportSize & 3) == 0);
	((UInt32*)&fSenderReportBuffer)[(fSenderReportSize >> 2) + 1] = htonl(inSSRC);
}

inline void	RTCPSRPacket::SetNTPTimestamp(SInt64 inNTPTimestamp)
{
#if ALLOW_NON_WORD_ALIGN_ACCESS
	((SInt64*)&fSenderReportBuffer)[1] = OS::HostToNetworkSInt64(inNTPTimestamp);
#else
	SInt64 temp = OS::HostToNetworkSInt64(inNTPTimestamp);
	::memcpy(&((SInt64*)&fSenderReportBuffer)[1], &temp, sizeof(temp));
#endif
}

inline void	RTCPSRPacket::SetRTPTimestamp(UInt32 inRTPTimestamp)
{
	((UInt32*)&fSenderReportBuffer)[4] = htonl(inRTPTimestamp);
}

inline void	RTCPSRPacket::SetPacketCount(UInt32 inPacketCount)
{
	((UInt32*)&fSenderReportBuffer)[5] = htonl(inPacketCount);
}

inline void	RTCPSRPacket::SetByteCount(UInt32 inByteCount)
{
	((UInt32*)&fSenderReportBuffer)[6] = htonl(inByteCount);
}	

#endif //__RTCP_SR_PACKET__