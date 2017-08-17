# Assets
EDGE provides assets, for example, binary input, in a [separate repository]({{book.edge_opt}}).
Due to limitations of git, when it comes to large files, we use [Git Large File Storage](https://git-lfs.github.com/) (Git LFS) in this repository.
To use EDGE's assets repository, *install the Git LFS command-line client* by following the linked instructions.
Futher background information and documentation on Git LFS is available at https://www.atlassian.com/git/tutorials/git-lfs.

## Obtaining Data
* The best performance, when cloning [EDGE's asset repository]({{book.edge_opt}}), is obtained by using `git lfs clone`. This will download all, possibly large, files stored in the Git LFS store.
* If you are only interested in certain files or directories, you can, by using `git lfs clone --exclude=*`, initialize the assets repository with non-LFS files and Git LFS pointers only.
Now, to obtain only a certain file or directories, use `git lfs fetch` with the arguments `-I` and `-X`. For example `git lfs fetch -I test/*` would download all files and directories in the directory `test`.
After downloading the files from the remote Git LFS store, you can replace the Git LFS pointers in your local Git repository with the actual files through `git lfs checkout test/*`.
