#pragma once

#include <libsmbclient.h>
#include <string>
#include <vector>

using std::string;
using std::vector;

// C++ wrapper for libsmbclient.

class SMBContext;

// Files returned by SMBContext.
class SMBFile
{
public:
	SMBFile();
	~SMBFile();
	
	SMBFile(SMBContext* ctx, SMBCFILE* f);
	
	// SMBClient functions.
	
	// Files.
	ssize_t Read(void* buf, size_t count);
	ssize_t Write(const void* buf, size_t count);
	off_t Seek(off_t offset, int whence);
	int Stat(struct stat* st);
	int Close();
	
	bool Valid() const { return file != NULL; }
	
	// Shallow copying.
	SMBFile(const SMBFile& F);
	const SMBFile& operator=(const SMBFile& F);
private:
	int* RefCount;
	
	// For communication with SMBContext.
	friend class SMBContext;
	void SMBContextDestroyed();
	SMBContext* context;
	
	SMBCFILE* file;
};

// Dirs returned by SMBContext.
class SMBDir
{
public:
	SMBDir();
	~SMBDir();
	
	SMBDir(SMBContext* ctx, SMBCFILE* d);
	
	// SMBClient functions.
	
	// Dirs.
	int Close();
	smbc_dirent* Read();
	int GetDEnts(smbc_dirent* dirp, int count);
	off_t Tell();
	int Seek(off_t offset);
	int Stat(struct stat* st);	
	
	bool Valid() const { return dir != NULL; }
		
	// Shallow copying.
	SMBDir(const SMBDir& D);
	const SMBDir& operator=(const SMBDir& D);
private:
	int* RefCount;
	
	// For communication with SMBContext.
	friend class SMBContext;
	void SMBContextDestroyed();
	SMBContext* context;
	
	SMBCFILE* dir;
};

// The context used for connecting to servers.
class SMBContext
{
public:
	SMBContext();
	~SMBContext();
	
	// SMBClient functions.
	bool Valid() const { return context != NULL; }
	void SetTimeout(int millisecs);
	
	// Files.
	SMBFile Open(const string& fname, int flags, mode_t mode);
	SMBFile Create(const string& path, mode_t mode);
	int Unlink(const string& fname);
	int Rename(const string& oname, const string& nname);
	int Stat(const string& fname, struct stat* st);
	
	// Dirs.
	SMBDir OpenDir(const string& fname);
	int MkDir(const string& fname, mode_t mode);
	int RmDir(const string& fname);
	int ChMod(const string& fname, mode_t mode);
	int UTimes(const string& fname, timeval* tbuf);
	int SetAttr(const string& fname, const string& name,
	            const void* value, size_t size, int flags);
	int GetAttr(const string& fname, const string& name,
	            void* value, size_t size);
	int RemoveAttr(const string& fname, const string& name);
	int ListAttr(const string& fname, char *list, size_t size);	
	
	// Printing.
	int PrintFile(const string& fname, const string& printq);
	SMBFile OpenPrintJob(const string& fname);
	int ListPrintJobs(const string& fname, smbc_list_print_job_fn fn);
	int UnlinkPrintJob(const string& fname, int id);
	
	// Temporary workaround for libsmbclient bug. Closes all files!
	void Reinitialise();
    
    void SetUser(const string& user, const string& pass, const string& workgroup);
	
private:
	// No copying.
	SMBContext(const SMBContext&);
	const SMBContext& operator=(const SMBContext&);
	
	// For communication with SMBFiles.
	friend class SMBFile;
	friend class SMBDir;
	void SMBFileCreated(SMBFile* F);
	void SMBDirCreated(SMBDir* D);
	void SMBFileDestroyed(SMBFile* F);
	void SMBDirDestroyed(SMBDir* D);
	vector<SMBFile*> SMBFiles;
	vector<SMBDir*> SMBDirs;
	
	// The context.
	SMBCCTX* context;
};

string EncodeSMBURL(const string& S);
string DecodeSMBURL(const string& S);


