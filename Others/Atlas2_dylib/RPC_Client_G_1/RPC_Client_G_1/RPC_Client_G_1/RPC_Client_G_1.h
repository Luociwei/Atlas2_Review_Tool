//
//  RPC_Client.h
//  RPC_Client
//

//

#import <Foundation/Foundation.h>
#ifndef RPC_CLIENT_G_1_H
#define RPC_CLIENT_G_1_H

#import <Foundation/Foundation.h>
#include <stdio.h>
#include <string>

#import <pthread.h>

#include "Publisher.hpp"
#include "Replier.hpp"
#import <mix_rpc_client_framework/mix_rpc_client_framework.h>

class RPC_Client_G_1 : CPubliser, CReplier
{
public:
    RPC_Client_G_1();
    RPC_Client_G_1(const char* filePath);
    ~RPC_Client_G_1();
    
    int CreateIPC(const char* reply, const char* publish);
    int CreateRepPubPort(const char* rep, const char* pub,int channel);  //control cylinder,only channel 0 can control
    int initWithEndpoint(const char* requester, const char* receiver);
    int initWithEndpoint(const char* requester, const char* receiver, int interval_ms, int retries);
    int isServerReady();
    const char* getServerMode();
    const char* isServerUpToDate();
    
    const char* rpc_client(const char* command,int timeout=3000);
    const char* rpc_client2(const char* command,int timeout=3000);
    int UnLockSendCmd();
    int sendFile(const char* srcFile, const char* Folder, int timeout);
    const char* getFile(const char* target, int timeout);
    int getAndWriteFile(const char* target, const char* dest, int timeout);
    
    void * m_SocketReply;
    void * m_ContextReply_automation;
    void * m_SocketReply_automation;
    
protected:
    pthread_t m_hTrhead;
    static void * ReadDataInBackGround(void * arg);
    int CreateREP_automation(const char *reply);

private:
    virtual void *OnRequest(void *pdata, long len);
    int LockSendCmd(const char * szLockName);
    int UnLockSendCmd(const char * szLockName);
    FILE * fp;
    bool bNeedZmq;
    RPCClientWrapper* m_Client;
    NSLock* m_lockBuffer;

    NSMutableDictionary *ENDPOINT;
    NSMutableDictionary* NON_EXISTING_ENDPOINT;
    NSMutableDictionary *dic_rpcCommand;
    
    //CZMQServer * m_zmqServer;
    pthread_t m_thread;
    void * m_ContextPublisher;
    void * m_ContextReply;
    void * m_SocketPublisher;

    
};


#endif /* RPC_Client.h */

