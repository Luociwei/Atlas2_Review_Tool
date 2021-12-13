#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

NS_ASSUME_NONNULL_BEGIN

NSSet *allowedClasses(void);

BOOL isAllowedClass(Class c);

BOOL isAllowedObject(NSObject *obj);

BOOL checkConstants(id obj);

NS_ASSUME_NONNULL_END

#ifdef __cplusplus
}
#endif
