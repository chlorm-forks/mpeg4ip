/*
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 * 
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 * 
 * The Original Code is MPEG4IP.
 * 
 * The Initial Developer of the Original Code is Cisco Systems Inc.
 * Portions created by Cisco Systems Inc. are
 * Copyright (C) Cisco Systems Inc. 2000, 2001.  All Rights Reserved.
 * 
 * Contributor(s): 
 *		Dave Mackie		dmackie@cisco.com
 *		Bill May 		wmay@cisco.com
 */

#ifndef __MEDIA_FRAME_H__
#define __MEDIA_FRAME_H__

#include <sys/types.h>
#include <SDL.h>
#include "timestamp.h"

class CMediaFrame {
public:
	CMediaFrame(u_int16_t type = 0, 
		void* pData = NULL, u_int32_t dataLength = 0, 
		Timestamp timestamp = 0, Duration duration = 0) {

		m_pMutex = SDL_CreateMutex();
		if (m_pMutex == NULL) {
			// TBD throw exception;
		}
		m_refcnt = 1;
		m_type = type;
		m_pData = pData;
		m_dataLength = dataLength;
		m_timestamp = timestamp;
		m_duration = duration;
	}

	void AddReference(void) {
		if (SDL_LockMutex(m_pMutex) == -1) {
			// TBD throw exception;
		}
		m_refcnt++;
		if (SDL_UnlockMutex(m_pMutex) == -1) {
			// TBD throw exception;
		}
	}

	void RemoveReference(void) {
		if (SDL_LockMutex(m_pMutex) == -1) {
			// TBD throw exception;
		}
		m_refcnt--;
		if (SDL_UnlockMutex(m_pMutex) == -1) {
			// TBD throw exception;
		}
	}

	void operator delete(void* p) {
		CMediaFrame* me = (CMediaFrame*)p;
		if (SDL_LockMutex(me->m_pMutex) == -1) {
			// TBD throw exception;
		}
		if (me->m_refcnt > 0) {
			me->m_refcnt--;
		}
		if (me->m_refcnt > 0) {
			return;
		}
		free(me->m_pData);
		free(me);
	}

	// predefined types of frames
	static const u_int16_t UndefinedFrame 	=	0;
	static const u_int16_t PcmAudioFrame	=	1;
	static const u_int16_t Mp3AudioFrame 	=	2;
	static const u_int16_t AacAudioFrame 	=	3;
	static const u_int16_t YuvVideoFrame 	=	4;
	static const u_int16_t Mpeg4VideoFrame =	5;

	// get methods for properties

	u_int16_t GetType(void) {
		return m_type;
	}
	void* GetData(void) {
		return m_pData;
	}
	u_int32_t GetDataLength(void) {
		return m_dataLength;
	}
	Timestamp GetTimestamp(void) {
		return m_timestamp;
	}
	Duration GetDuration(void) {
		return m_duration;
	}

protected:
	SDL_mutex*	m_pMutex;
	u_int16_t	m_refcnt;
	u_int16_t	m_type;
	void* 		m_pData;
	u_int32_t 	m_dataLength;
	Timestamp	m_timestamp;
	Duration 	m_duration;
};

#endif /* __MEDIA_FRAME_H__ */
