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
 *              Bill May        wmay@cisco.com
 */
/*
 * player_rtp_bytestream.h - provides an RTP bytestream for the codecs
 * to access
 */

#ifndef __H261_RTP_PLUGIN_H__
#define __H261_RTP_PLUGIN_H__ 1
#include "rtp_plugin.h"
//#define H261_RTP_DUMP_OUTPUT_TO_FILE 1

typedef struct h261_rtp_data_t {
  rtp_plugin_data_t plug;

#ifdef H261_RTP_DUMP_OUTPUT_TO_FILE
  FILE *m_outfile;
#endif
  int      m_first_pak;
  uint16_t m_last_seq;
  rtp_packet *m_current_pak;
} h261_rtp_data_t;


#define m_vft plug.vft
#define m_ifptr plug.ifptr
#endif

