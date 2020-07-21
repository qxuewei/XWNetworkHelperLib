//
//  XWSafeMutableArray.h
//  AFNetworking
//
//  Created by 邱学伟 on 2020/7/21.
//  一个线程安全的 NSMutableArray

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XWSafeMutableArray : NSObject

- (void)addObject:(id)anObject;

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;

- (void)removeLastObject;

- (void)removeObject:(NSObject *)anObject;

- (void)removeAllObjects;

- (void)removeObjectAtIndex:(NSUInteger)index;

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;

- (id)objectAtIndex:(NSUInteger)index;

- (nullable id)getFirstObject;

- (nullable id)getLastObject;

- (void)enumerateObjectsUsingBlock:(void (NS_NOESCAPE ^)(id obj, NSUInteger idx, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
