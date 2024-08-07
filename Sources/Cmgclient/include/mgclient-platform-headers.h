//
//  Header.h
//  
//
//  Created by Peter Liddle on 8/4/24.
//

#ifndef MGCLIENT_PLATFORM_HEADERS
#define MGCLIENT_PLATFORM_HEADERS

#include <stdint.h>

// Include the mgclient.h header
#include "../mgclient/include/mgclient.h"

// Include platform-specific headers
#if defined(MGCLIENT_ON_APPLE)
#include "../mgclient/src/apple/mgcommon.h"
#elif defined(MGCLIENT_ON_LINUX)
#include "../mgclient/src/linux/mgcommon.h"
#elif defined(MGCLIENT_ON_WINDOWS)
#include "../mgclient/src/windows/mgcommon.h"
#endif

// MyCTypes.h

#ifndef MyCTypes_h
#define MyCTypes_h

#endif /* MyCTypes_h */
#endif /* mgclient-platform-headers */
