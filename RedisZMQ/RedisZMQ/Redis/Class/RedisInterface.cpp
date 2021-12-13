//
//  RedisInterface.cpp
//  RedisDriver


#include "RedisInterface.hpp"

#define CACHE_TYPE_1 1

unsigned int APHash(const char *str)
{
    unsigned int hash = 0;
    int i;
    
    for (i = 0; *str; i++) {
        if ((i & 1) == 0) {
            hash ^= ((hash << 7) ^ (*str++) ^ (hash >> 3));
        } else {
            hash ^= (~((hash << 11) ^ (*str++) ^ (hash >> 5)));
        }
    }
    
    return (hash & 0x7FFFFFFF);
}


RedisInterface::RedisInterface()
{
    xClient = new xRedisClient();
}

RedisInterface::~RedisInterface()
{
    
}

void RedisInterface::Connect()
{
    xClient->Init(Number);
    RedisList[0] =  {0, "127.0.0.1", 6379, "", 2, 5, 0};
    RedisList[1] =  {1, "127.0.0.1", 6379, "", 2, 5, 0};
    RedisList[2] =  {2, "127.0.0.1", 6379, "", 2, 5, 0};
    RedisList[3] =  {3, "127.0.0.1", 6379, "", 2, 5, 0};
    xClient->ConnectRedisCache(RedisList, sizeof(RedisList) / sizeof(RedisNode),Number, CACHE_TYPE_1);
}


bool RedisInterface::DelKey(const char *strkey)
{
    RedisDBIdx dbi(xClient);
    bool bRet = dbi.CreateDBIndex(strkey, APHash, CACHE_TYPE_1);
    if (bRet){
        if(xClient->del(dbi, strkey))
            return true;
    }
    return false;
}

bool RedisInterface::SetString(const char *strkey, const char *strValue)
{
    RedisDBIdx dbi(xClient);
    bool bRet = dbi.CreateDBIndex(strkey, APHash, CACHE_TYPE_1);
    if (bRet) {
        if (xClient->set(dbi, strkey, strValue)) {
            printf("%s success \r\n", __PRETTY_FUNCTION__);
        } else {
            printf("%s error [%s] \r\n", __PRETTY_FUNCTION__, dbi.GetErrInfo());
        }
    }
    return bRet;
}

const char * RedisInterface::GetString(const char *strkey)
{
    char szKey[256] = {0};
    {
        strcpy(szKey, strkey);
        RedisDBIdx dbi(xClient);
        bool bRet = dbi.CreateDBIndex(szKey, APHash, CACHE_TYPE_1);
        if (bRet) {
            resultData.clear();
            if (xClient->get(dbi, szKey, resultData)) {
                printf("%s success data:%s \r\n", __PRETTY_FUNCTION__, resultData.c_str());
                return resultData.c_str();
            } else {
                printf("%s error [%s] \r\n", __PRETTY_FUNCTION__, dbi.GetErrInfo());
            }
        }
    }
    return "";
}

bool RedisInterface::Lpush(const char *listName, const char * vValue)
{
    char szHKey[256] = { 0 };
    strcpy(szHKey, listName);
    VALUES vVal;
    vVal.push_back(vValue);
    RedisDBIdx dbi(xClient);
    bool bRet = dbi.CreateDBIndex(szHKey, APHash, CACHE_TYPE_1);
    if (bRet) {
        int64_t count = 0;
        if (xClient->lpush(dbi, szHKey, vVal, count)) {
            printf("%s success %lld \r\n", __PRETTY_FUNCTION__, count);
            return true;
        }
        else {
            printf("%s error [%s] \r\n", __PRETTY_FUNCTION__, dbi.GetErrInfo());
        }
    }
    return false;
}

const char * RedisInterface::Lpop(const char *listName)
{
    char szHKey[256] = { 0 };
    strcpy(szHKey, listName);
    RedisDBIdx dbi(xClient);
    bool bRet = dbi.CreateDBIndex(szHKey, APHash, CACHE_TYPE_1);
    if (bRet) {
        resultData.clear();
        if (xClient->lpop(dbi, szHKey, resultData)) {
            printf("%s success val: %s \r\n", __PRETTY_FUNCTION__, resultData.c_str());
            return resultData.c_str();
        }
        else {
            printf("%s error [%s] \r\n", __PRETTY_FUNCTION__, dbi.GetErrInfo());
        }
    }
    return "";
}

const char * RedisInterface::Rpop(const char *listName)
{
    char szHKey[256] = { 0 };
    strcpy(szHKey, listName);
    RedisDBIdx dbi(xClient);
    bool bRet = dbi.CreateDBIndex(szHKey, APHash, CACHE_TYPE_1);
    if (bRet) {
        resultData.clear();
        if (xClient->rpop(dbi, szHKey, resultData)) {
            printf("%s success val: %s \r\n", __PRETTY_FUNCTION__, resultData.c_str());
            return resultData.c_str();
        }
        else {
            printf("%s error [%s] \r\n", __PRETTY_FUNCTION__, dbi.GetErrInfo());
        }
    }
    return "";
}

int RedisInterface::Llen(const char *listName)
{
    char szHKey[256] = { 0 };
    strcpy(szHKey, listName);
    RedisDBIdx dbi(xClient);
    bool bRet = dbi.CreateDBIndex(szHKey, APHash, CACHE_TYPE_1);
    if (bRet) {
        int64_t count = 0;
        if (xClient->llen(dbi, szHKey, count)) {
            printf("%s success len: %lld \r\n", __PRETTY_FUNCTION__, count);
            return (int)count;
        }
        else {
            printf("%s error [%s] \r\n", __PRETTY_FUNCTION__, dbi.GetErrInfo());
        }
    }
    return 0;
}

void RedisInterface::Lremove(const char *listName, int count, const char * vValue)
{
    char szHKey[256] = { 0 };
    strcpy(szHKey, listName);
    RedisDBIdx dbi(xClient);
    bool bRet = dbi.CreateDBIndex(szHKey, APHash, CACHE_TYPE_1);
    if (bRet) {
        int64_t num = 0;
        if (xClient->lrem(dbi, szHKey, count, vValue, num)) {
            printf("%s success len: %lld \r\n", __PRETTY_FUNCTION__, num);
        }
        else {
            printf("%s error [%s] \r\n", __PRETTY_FUNCTION__, dbi.GetErrInfo());
        }
    }
}

bool RedisInterface::Hset(const char *hashName,const char *strkey, const char *strValue)
{
    char szHKey[256] = {0};
    strcpy(szHKey, hashName);
    RedisDBIdx dbi(xClient);
    bool bRet = dbi.CreateDBIndex(szHKey, APHash, CACHE_TYPE_1);
    if (bRet) {
        int64_t count = 0;
        if (xClient->hset(dbi, szHKey, strkey, strValue, count)) {
            printf("%s success \r\n", __PRETTY_FUNCTION__);
            return true;
        } else {
            printf("%s error [%s] \r\n", __PRETTY_FUNCTION__, dbi.GetErrInfo());
        }
    }
    return false;
}

const char * RedisInterface::Hget(const char *hashName,const char *strkey)
{
    char szHKey[256] = {0};
    strcpy(szHKey, hashName);
    RedisDBIdx dbi(xClient);
    bool bRet = dbi.CreateDBIndex(szHKey, APHash, CACHE_TYPE_1);
    if (bRet) {
        resultData.clear();
        if (xClient->hget(dbi, szHKey, strkey, resultData)) {
            printf("%s success %s \r\n", __PRETTY_FUNCTION__, resultData.c_str());
            return resultData.c_str();
        } else {
            printf("%s error [%s] \r\n", __PRETTY_FUNCTION__, dbi.GetErrInfo());
        }
    }
    return "";
}

bool RedisInterface::Hdel(const char *hashName,const char *strkey)
{
    char szHKey[256] = {0};
    strcpy(szHKey, hashName);
    RedisDBIdx dbi(xClient);
    bool bRet = dbi.CreateDBIndex(szHKey, APHash, CACHE_TYPE_1);
    if (bRet) {
        int64_t count = 0;
        if (xClient->hdel(dbi, szHKey, strkey, count))
            return true;
    }
    return false;
}

void RedisInterface::Hscan()
{
    char* pattern = "a*";
    RedisDBIdx dbi(xClient);
    bool bRet = dbi.CreateDBIndex(0, CACHE_TYPE_1);
    if (!bRet) {
        return;
    }
    
    ArrayReply arrayReply;
    int64_t cursor = 0;
    xRedisContext ctx;
    xClient->GetxRedisContext(dbi, &ctx);
    
    do
    {
        arrayReply.clear();
        if (xClient->scan(dbi, cursor, pattern, 0, arrayReply, ctx)) {
            printf("%lld\t\r\n", cursor);
            ReplyData::iterator iter = arrayReply.begin();
            for (; iter != arrayReply.end(); iter++) {
                printf("\t\t%s\r\n",  (*iter).str.c_str());
            }
        } else {
            printf("%s error [%s] \r\n", __PRETTY_FUNCTION__, dbi.GetErrInfo());
            break;
        }
    } while (cursor != 0);
    xClient->FreexRedisContext(&ctx);
}
