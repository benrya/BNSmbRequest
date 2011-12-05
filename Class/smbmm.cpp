#include "smbmm.h"

#include <errno.h>
#include <iostream>

#ifdef __SMBMM_OLD_CLOSE__
// Close instead of close_fn in earlier libsmbclients.
#define close_fn close
#endif

using namespace std;

char UserName[128] = "";
char PassWord[128] = "";
char WorkGroup[128] = "";

void libsmbmm_guest_auth_smbc_get_data(const char *server,const char *share,
                              char *workgroup, int wgmaxlen,
                              char *username, int unmaxlen,
                              char *password, int pwmaxlen)
{
    if (UserName && strcmp(UserName,"") > 0) {
        strncpy(username, UserName, unmaxlen - 1);
    } else {
        strncpy(username, "guest", unmaxlen - 1);
    }
    
    if (PassWord) {
        strncpy(password, PassWord, pwmaxlen - 1);
    } else {
        strncpy(password, "", pwmaxlen - 1);
    }
    
    if (WorkGroup) {
        strncpy(workgroup, WorkGroup, wgmaxlen - 1);	
    } else {
        strncpy(workgroup, "", wgmaxlen - 1);	
    }
}

/** ************************************************ SMBContext **************************************************/

SMBContext::SMBContext() : context(NULL)
{
	// Create a new context.
	context = smbc_new_context();
	if (!context)
	{
		// ### Error creating context.
		cerr << "Error creating SMBContext." << endl;
		return;
	}
	
	context->debug = 0;
	context->timeout = 1000;
	context->callbacks.auth_fn = libsmbmm_guest_auth_smbc_get_data;
	if (!smbc_init_context(context))
	{
		// ### Error initialising new context.
		cerr << "Error initalising SMBContext." << endl;
		smbc_free_context(context, false);
		context = NULL;
		return;
	}
}
SMBContext::~SMBContext()
{
	for (unsigned int i = 0; i < SMBFiles.size(); ++i)
	{
		if (SMBFiles[i])
			SMBFiles[i]->SMBContextDestroyed();
	}
	for (unsigned int i = 0; i < SMBDirs.size(); ++i)
	{
		if (SMBDirs[i])
			SMBDirs[i]->SMBContextDestroyed();
	}
	if (context)
		smbc_free_context(context, false);
}

void SMBContext::Reinitialise()
{
	for (unsigned int i = 0; i < SMBFiles.size(); ++i)
	{
		if (SMBFiles[i])
			SMBFiles[i]->SMBContextDestroyed();
	}
	SMBFiles.clear();
	for (unsigned int i = 0; i < SMBDirs.size(); ++i)
	{
		if (SMBDirs[i])
			SMBDirs[i]->SMBContextDestroyed();
	}
	SMBDirs.clear();
	int OldTimeout = 1000;
	if (context)
	{
		OldTimeout = context->timeout;
		smbc_free_context(context, false);
	}
	
	// Create a new context.
	context = smbc_new_context();
	if (!context)
	{
		// ### Error creating context.
		cerr << "Error creating SMBContext." << endl;
		return;
	}
	
	context->debug = 0;
	context->timeout = OldTimeout;
	context->callbacks.auth_fn = libsmbmm_guest_auth_smbc_get_data;
	if (!smbc_init_context(context))
	{
		// ### Error initialising new context.
		cerr << "Error initalising SMBContext." << endl;
		smbc_free_context(context, false);
		context = NULL;
		return;
	}	
}

//Add by benrya
void SMBContext::SetUser(const string& user, const string& pass, const string& workgroup) 
{
    if (!context) {
        return;
    }
    if (&user != NULL) {
        strcpy(UserName, user.c_str());
    }
    if (&pass != NULL) {
        strcpy(PassWord,pass.c_str());
    }
    if (&workgroup != NULL) {
        strcpy(WorkGroup, workgroup.c_str());
    }
}


// SMBClient functions.
void SMBContext::SetTimeout(int millisecs)
{
	if (!context)
		return;
	
	context->timeout = millisecs >= 0 ? millisecs : 0;
}		

// Files.
SMBFile SMBContext::Open(const string& fname, int flags, mode_t mode)
{
	if (!context)
		return SMBFile();
	
	SMBCFILE* file = context->open(context, fname.c_str(), flags, mode);
	
	if (!file)
		return SMBFile();
	
	return SMBFile(this, file);
}
SMBFile SMBContext::Create(const string& path, mode_t mode)
{
	if (!context)
		return SMBFile();
	
	SMBCFILE* file = context->creat(context, path.c_str(), mode);
	
	if (!file)
		return SMBFile();
	
	return SMBFile(this, file);
}
int SMBContext::Unlink(const string& fname)
{
	if (!context)
		return EINVAL;
	
	return context->unlink(context, fname.c_str());
}
int SMBContext::Rename(const string& oname, const string& nname)
{
	if (!context)
		return EINVAL;
	
	return context->rename(context, oname.c_str(), context, nname.c_str());
}
int SMBContext::Stat(const string& fname, struct stat* st)
{
	if (!context || !st)
		return EINVAL;
	
	return context->stat(context, fname.c_str(), st);
}

// Dirs.
SMBDir SMBContext::OpenDir(const string& fname)
{
	if (!context)
		return SMBDir();
	
	SMBCFILE* dir = context->opendir(context, fname.c_str());
	
	if (!dir)
		return SMBDir();
	
	return SMBDir(this, dir);	
}
int SMBContext::MkDir(const string& fname, mode_t mode)
{
	if (!context)
		return EINVAL;
	
	return context->mkdir(context, fname.c_str(), mode);
}
int SMBContext::RmDir(const string& fname)
{
	if (!context)
		return EINVAL;
	
	return context->rmdir(context, fname.c_str());
}
int SMBContext::ChMod(const string& fname, mode_t mode)
{
	if (!context)
		return EINVAL;
	
	return context->chmod(context, fname.c_str(), mode);
}
int SMBContext::UTimes(const string& fname, timeval* tbuf)
{
	if (!context || !tbuf)
		return EINVAL;
	
	return context->utimes(context, fname.c_str(), tbuf);
}
int SMBContext::SetAttr(const string& fname, const string& name,
			const void* value, size_t size, int flags)
{
	if (!context || !value)
		return EINVAL;
	
	return context->setxattr(context, fname.c_str(), name.c_str(), value, size, flags);
}
int SMBContext::GetAttr(const string& fname, const string& name,
			void* value, size_t size)
{
	if (!context || !value)
		return EINVAL;
	
	// FIXME const is wrong here.
	return context->getxattr(context, fname.c_str(), name.c_str(), value, size);
}
int SMBContext::RemoveAttr(const string& fname, const string& name)
{
	if (!context)
		return EINVAL;
	
	return context->removexattr(context, fname.c_str(), name.c_str());
}
int SMBContext::ListAttr(const string& fname, char *list, size_t size)
{
	if (!context || !list)
		return EINVAL;
	
	return context->listxattr(context, fname.c_str(), list, size);
}	

// Printing.
int SMBContext::PrintFile(const string& fname, const string& printq)
{
	if (!context)
		return EINVAL;
	
	return context->print_file(context, fname.c_str(), context, printq.c_str());
}
SMBFile SMBContext::OpenPrintJob(const string& fname)
{
	if (!context)
		return SMBFile();
	
	SMBCFILE* file = context->open_print_job(context, fname.c_str());
	
	if (!file)
		return SMBFile();
	
	return SMBFile(this, file);
}
int SMBContext::ListPrintJobs(const string& fname, smbc_list_print_job_fn fn)
{
	if (!context || !fn)
		return EINVAL;
	
	return context->list_print_jobs(context, fname.c_str(), fn);
}
int SMBContext::UnlinkPrintJob(const string& fname, int id)
{
	if (!context)
		return EINVAL;
	
	return context->unlink_print_job(context, fname.c_str(), id);
}

// For communication with SMBFiles.
void SMBContext::SMBFileCreated(SMBFile* F)
{
	SMBFiles.push_back(F);
}
void SMBContext::SMBDirCreated(SMBDir* D)
{
	SMBDirs.push_back(D);
}
void SMBContext::SMBFileDestroyed(SMBFile* F)
{
	SMBFiles.erase(remove(SMBFiles.begin(), SMBFiles.end(), F), SMBFiles.end());
}
void SMBContext::SMBDirDestroyed(SMBDir* D)
{
	SMBDirs.erase(remove(SMBDirs.begin(), SMBDirs.end(), D), SMBDirs.end());
}

/** ************************************************ SMBFile **************************************************/

SMBFile::SMBFile() : context(NULL), file(NULL), RefCount(NULL)
{
}
SMBFile::~SMBFile()
{
	if (context)
		context->SMBFileDestroyed(this);
	
	if (RefCount && --*RefCount < 1)
	{
		Close();
		delete RefCount;
	}
}
SMBFile::SMBFile(SMBContext* ctx, SMBCFILE* f) : context(ctx), file(f), RefCount(NULL)
{
	if (!context)
	{
		// Nothing we can do really. Have to let it leak.
		file = NULL;
		return;
	}
	
	RefCount = new int;
	if (RefCount)
		*RefCount = 1;
	
	context->SMBFileCreated(this);
}
SMBFile::SMBFile(const SMBFile& F)
{	
	context = F.context;
	file = F.file;
	RefCount = F.RefCount;

	if (RefCount)
		++*RefCount;
	if (context)
		context->SMBFileCreated(this);
}
const SMBFile& SMBFile::operator=(const SMBFile& F)
{
	if (RefCount == F.RefCount)
		return *this;
	
	if (context)
		context->SMBFileDestroyed(this);

	if (RefCount && --*RefCount < 1)
	{
		Close();
		delete RefCount;
	}
	
	context = F.context;
	file = F.file;
	RefCount = F.RefCount;

	if (RefCount)
		++*RefCount;
	if (context)
		context->SMBFileCreated(this);
	
	return *this;
}

// SMBClient functions.

// Files.
ssize_t SMBFile::Read(void* buf, size_t count)
{
	if (!context || !context->context || !file || !buf)
		return -1;
	
	return context->context->read(context->context, file, buf, count);
}
ssize_t SMBFile::Write(const void* buf, size_t count)
{
	if (!context || !context->context || !file || !buf)
		return -1;
	
	// FIXME libsmbclient constness error.
	return context->context->write(context->context, file, const_cast<void*>(buf), count);
}
off_t SMBFile::Seek(off_t offset, int whence)
{
	if (!context || !context->context || !file)
		return -1;
	
	return context->context->lseek(context->context, file, offset, whence);
}
int SMBFile::Stat(struct stat* st)
{
	if (!context || !context->context || !file || !st)
		return EINVAL;
	
	return context->context->fstat(context->context, file, st);	
}
int SMBFile::Close()
{
	if (!context || !context->context || !file)
		return EINVAL;
	
	// Close instead of close_fn in earlier libsmbclients.
	int r = context->context->close_fn(context->context, file);
	
	if (r != 0)
		return r;
	
	file = NULL;
	return 0;		
}

// For communication with SMBContext.
void SMBFile::SMBContextDestroyed()
{
	if (RefCount && --*RefCount < 1)
	{
		Close();
		context = NULL;
		if (RefCount)
			delete RefCount;
	}
}

/** ************************************************ SMBDir **************************************************/


SMBDir::SMBDir() : context(NULL), dir(NULL), RefCount(NULL)
{
}
SMBDir::~SMBDir()
{
	if (context)
		context->SMBDirDestroyed(this);
	
	if (RefCount && --*RefCount < 1)
	{
		Close();
		delete RefCount;
	}
}
SMBDir::SMBDir(SMBContext* ctx, SMBCFILE* d) : context(ctx), dir(d), RefCount(NULL)
{
	if (!context)
	{
		// Nothing we can do really. Have to let it leak.
		dir = NULL;
		return;
	}
	
	RefCount = new int;
	if (RefCount)
		*RefCount = 1;
	
	context->SMBDirCreated(this);
}
SMBDir::SMBDir(const SMBDir& D)
{
	context = D.context;
	dir = D.dir;
	RefCount = D.RefCount;

	if (RefCount)
		++*RefCount;
	if (context)
		context->SMBDirCreated(this);
}
const SMBDir& SMBDir::operator=(const SMBDir& D)
{
	if (RefCount == D.RefCount)
		return *this;
	
	if (context)
		context->SMBDirDestroyed(this);

	if (RefCount && --*RefCount < 1)
	{
		Close();
		delete RefCount;
	}
	
	context = D.context;
	dir = D.dir;
	RefCount = D.RefCount;

	if (RefCount)
		++*RefCount;
	if (context)
		context->SMBDirCreated(this);
	
	return *this;
}

// SMBClient functions.

// Dirs.
int SMBDir::Close()
{
	if (!context || !context->context || !dir)
		return EINVAL;
	
	int r = context->context->closedir(context->context, dir);
	
	if (r != 0)
		return r;
	
	dir = NULL;
	return 0;
}
smbc_dirent* SMBDir::Read()
{
	if (!context || !context->context || !dir)
		return NULL;
	
	return context->context->readdir(context->context, dir);
}
int SMBDir::GetDEnts(smbc_dirent* dirp, int count)
{
	if (!context || !context->context || !dir || !dirp)
		return EINVAL;
	
	return context->context->getdents(context->context, dir, dirp, count);
}
off_t SMBDir::Tell()
{
	if (!context || !context->context || !dir)
		return -1;
	
	return context->context->telldir(context->context, dir);
}
int SMBDir::Seek(off_t offset)
{
	if (!context || !context->context || !dir)
		return EINVAL;
	
	return context->context->lseekdir(context->context, dir, offset);
}
int SMBDir::Stat(struct stat* st)
{
	if (!context || !context->context || !dir || !st)
		return EINVAL;
	
	return context->context->fstatdir(context->context, dir, st);
}	

// For communication with SMBContext.
void SMBDir::SMBContextDestroyed()
{
	if (RefCount && --*RefCount < 1)
	{
		Close();
		context = NULL;
		if (RefCount)
			delete RefCount;
	}
}


string EncodeSMBURL(const string& S)
{
	char* Dest = new char[S.length() * 3 + 1];
	
	// Maybe should be S.length() * 3 + 1, but I'm not sure.
	int r = smbc_urlencode(Dest, const_cast<char*>(S.c_str()), S.length() * 3);
	if (r <= 0)
		cerr << "Warning: URL encoding buffer overflow." << endl;
	
	string Ret = Dest;
	delete[] Dest;
	return Ret;
}
string DecodeSMBURL(const string& S)
{
	char* Dest = new char[S.length() + 1];
	
	// Maybe should be S.length() + 1, but I'm not sure.
	smbc_urldecode(Dest, const_cast<char*>(S.c_str()), S.length());
	
	string Ret = Dest;
	delete[] Dest;
	return Ret;	
}
