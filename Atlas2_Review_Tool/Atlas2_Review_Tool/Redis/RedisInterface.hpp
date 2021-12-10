//
//  RedisInterface.hpp
//  RedisDriver
//

#ifndef RedisInterface_hpp
#define RedisInterface_hpp

#include <stdio.h>
#include "xRedisClient.h"


class RedisInterface
{
public:
    RedisInterface();
    ~RedisInterface();
    RedisInterface(const RedisInterface &) = delete;
    RedisInterface& operator=(RedisInterface&) = delete;
public:
    void Connect();
    /****************string*************************/
    bool SetString(const char *strkey, const char *strValue);
    const char * GetString(const char *strkey);
    bool DelKey(const char *strkey);
    /****************list***************************/
    bool Lpush(const char *listName, const char * vValue);
    const char *Lpop(const char *listName);
    const char *Rpop(const char *listName);
    int Llen(const char *listName);
    void Lremove(const char *listName, int count, const char * vValue); //count == 0,删除list中所有值为vValue的数据
    /****************hash***************************/
    bool Hset(const char *hashName,const char *strkey, const char *strValue);
    const char * Hget(const char *hashName,const char *strkey);
    bool Hdel(const char *hashName,const char *strkey);
    void Hscan(); //迭代哈希表中的所有键值对
    /****************set****************************/
    /****************pub sub************************/
    
private:
    enum NUM {Number = 4};
    std::string resultData;
    xRedisClient *xClient;
    RedisNode RedisList[Number];
};

#endif /* RedisInterface_hpp */
