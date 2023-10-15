
Need to work out how to use statx via luajits ffi so I can get lfs_ffi working on arm64 which has no stat or lstat but does have a statx.

This involves lots of magic numbers so plenty of places to get things wrong

Right now it is not working mysteriously.
