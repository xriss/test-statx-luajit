
local ffi = require "ffi"


--[[

This struct may be totally wrong, not at the point where I can test how 
it fills in yet and it was created by eye from `man statx`

]]

ffi.cdef([[
   typedef struct {
	   uint32_t stx_mask;        /* Mask of bits indicating
								 filled fields */
	   uint32_t stx_blksize;     /* Block size for filesystem I/O */
	   uint64_t stx_attributes;  /* Extra file attribute indicators */
	   uint32_t stx_nlink;       /* Number of hard links */
	   uint32_t stx_uid;         /* User ID of owner */
	   uint32_t stx_gid;         /* Group ID of owner */
	   uint16_t stx_mode;        /* File type and mode */
	   uint64_t stx_ino;         /* Inode number */
	   uint64_t stx_size;        /* Total size in bytes */
	   uint64_t stx_blocks;      /* Number of 512B blocks allocated */
	   uint64_t stx_attributes_mask;
							  /* Mask to show what's supported
								 in stx_attributes */

	   /* The following fields are file timestamps */
	   int64_t stx_atime;  /* Last access */
	   uint32_t stx_atime_ms;
	   int64_t stx_btime;  /* Creation */
	   uint32_t stx_btime_ms;
	   int64_t stx_ctime;  /* Last status change */
	   uint32_t stx_ctime_ms;
	   int64_t stx_mtime;  /* Last modification */
	   uint32_t stx_mtime_ms;

	   /* If this file represents a device, then the next two
		  fields contain the ID of the device */
	   uint32_t stx_rdev_major;  /* Major ID */
	   uint32_t stx_rdev_minor;  /* Minor ID */

	   /* The next two fields contain the ID of the device
		  containing the filesystem where the file resides */
	   uint32_t stx_dev_major;   /* Major ID */
	   uint32_t stx_dev_minor;   /* Minor ID */

	   uint64_t stx_mnt_id;      /* Mount ID */

	   /* Direct I/O alignment restrictions */
	   uint32_t stx_dio_mem_align;
	   uint32_t stx_dio_offset_align;

   } statx;
]])

        ffi.cdef([[
            typedef struct lfs_stat {
                unsigned long   st_dev;
                unsigned long   st_ino;
                unsigned long   st_nlink;
                unsigned int    st_mode;
                unsigned int    st_uid;
                unsigned int    st_gid;
                unsigned int    __pad0;
                unsigned long   st_rdev;
                long            st_size;
                long            st_blksize;
                long            st_blocks;
                unsigned long   st_atime;
                unsigned long   st_atime_nsec;
                unsigned long   st_mtime;
                unsigned long   st_mtime_nsec;
                unsigned long   st_ctime;
                unsigned long   st_ctime_nsec;
                long            __unused[3];
            } lfs_stat;
        ]])

--[[

functions

]]
ffi.cdef([[
	long syscall(int number, ...);
    char* strerror(int errnum);

	int stat(const char *pathname,
         struct lfs_stat *statbuf);
         
	int lstat(const char *pathname,
         struct lfs_stat *statbuf);
]])

--[[

These syscall numbers can be yamnked out of an operating system by 
running something like.

	printf SYS_statx | gcc -include sys/syscall.h -E - | tail -n1

Which should print whatever value SYS_statx is defined to in syscall.h 
or just SYS_statx if it is not defined.

This is how I realised that SYS_stat was not available on arm64 and 
this rabbit hole began.

]]

local syscall_statx_num
if     ffi.arch == "arm64" then	syscall_statx_num = 291
elseif ffi.arch == "x64"   then syscall_statx_num = 332
end

-- statx wrapper
local syscall_statx=function(file,path,flags,mask,result)

	file   = file   or -100
	path   = path   or ""
	flags  = flags  or 0x5800
	mask   = mask   or 0x02
	result = result or ffi.new("lfs_stat")
	
--	local err = ffi.C.syscall( syscall_statx_num , file , path , flags , mask , result )

	local err = ffi.C.stat( path , result )

    if tonumber( err )  == -1 then
        return nil , string.format( "statx of '%s' failed : %s" , tostring(path) , ffi.string( ffi.C.strerror( ffi.errno() ) ) )
    end

	return result
end

-- try and call statx
local result=assert( syscall_statx(-100,"test.lua",0x5800,0x02) )

print(result,result.st_mode,result.st_size)
