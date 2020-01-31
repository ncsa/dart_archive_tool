////////////////////////////////////////////////////////////////////////////////
// 
//  University of Illinois/NCSA Open Source License
//  http://otm.illinois.edu/disclose-protect/illinois-open-source-license
//  
//  Parfu is copyright © 2017-2020, 
//  by The Trustees of the University of Illinois. 
//  All rights reserved.
//  
//  Parfu was developed by:
//  The University of Illinois
//  The National Center For Supercomputing Applications (NCSA)
//  Blue Waters Science and Engineering Applications Support Team (SEAS)
//  Craig P Steffen <csteffen@ncsa.illinois.edu>
//  Roland Haas <rhaas@illinois.edu>
//  
//  https://github.com/ncsa/parfu_archive_tool
//  http://www.ncsa.illinois.edu/People/csteffen/parfu/
//  
//  For full licnse text see the LICENSE file provided with the source
//  distribution.
//  
////////////////////////////////////////////////////////////////////////////////

#ifndef PARFU_MASTER_HH_
#define PARFU_MASTER_HH_

#include <cstdio>
#include <sys/types.h>
#include <sys/stat.h>

#include <iostream>
#include <string>
#include <vector>

#include "tarentry.hh"

using namespace std;

// classes to define for new structure of parfu
// file: (contains information about target file file on disk)
//       (also contains a list of one or more subfiles)
// subfile: specifies location of subfile within file, and also within container
// pad_file: subclass of subfile; specifies location of padding file within container
// dir: contains information about a directory
//      whether the directory has been spidered
//      if it has been spidered, a list of things within it
//      contains a list of subdirs
//      contains a list of subfiles
//      may be serializable to be passed across MPI
// container_file: contains all the informationa about a container file
//      file pointers, state, etc.  
//      contains list of objects who will reside in the container file 
//         when written to disk.  So a list of submfiles and/or container slices
//      actually probably contains a list of container slides, maybe instead of the above
// container_slice: nicely-sized chunk of container file. written to container file by 
//     one rank
// node_boss: contains a work order for the master rank of a node to process
// node_worker: contains list that a thread on a node should process




#endif  // #ifndef PARFU_MASTER_HH_
