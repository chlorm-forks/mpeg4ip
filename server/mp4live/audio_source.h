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

#ifndef __AUDIO_SOURCE_H__
#define __AUDIO_SOURCE_H__

#include <sys/types.h>
#include <sys/ioctl.h>
#include <linux/soundcard.h>

#include "media_node.h"
#include "audio_encoder.h"

class CAudioSource : public CMediaSource {
public:
	CAudioSource() : CMediaSource() {
		m_capture = false;
		m_audioDevice = -1;
		m_encoder = NULL;
		m_rawFrameBuffer = NULL;
	}
	~CAudioSource() {
		delete m_encoder;
		free(m_rawFrameBuffer);
	}

	void StartCapture(void) {
		m_myMsgQueue.send_message(MSG_START_CAPTURE,
			NULL, 0, m_myMsgQueueSemaphore);
	}

	void StopCapture(void) {
		m_myMsgQueue.send_message(MSG_STOP_CAPTURE,
			NULL, 0, m_myMsgQueueSemaphore);
	}

protected:
	static const int MSG_START_CAPTURE	= 1;
	static const int MSG_STOP_CAPTURE	= 2;

	int ThreadMain(void);

	void DoStartCapture(void);
	void DoStopCapture(void);

	bool Init(void);
	bool InitDevice(void);
	bool InitEncoder(void);

	void ProcessAudio(void);
	u_int16_t ForwardEncodedFrames(void);

protected:
	bool				m_capture;
	int					m_audioDevice;
	CAudioEncoder*		m_encoder;
	u_int16_t			m_frameType;
	Timestamp			m_startTimestamp;
	u_int32_t			m_frameNumber;
	u_int16_t			m_maxPasses;

	Duration			m_rawFrameDuration;
	u_int16_t			m_rawSamplesPerFrame;
	u_int16_t*			m_rawFrameBuffer;
	u_int32_t			m_rawFrameSize;

	Duration			m_encodedFrameDuration;
};

#endif /* __AUDIO_SOURCE_H__ */
