//
//  XWSafeMutableArray.m
//  AFNetworking
//
//  Created by 邱学伟 on 2020/7/21.
//

#import "XWSafeMutableArray.h"

@interface XWSafeMutableArray()
@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, strong) dispatch_queue_t concurrentQuene;
@end

@implementation XWSafeMutableArray
- (instancetype)init {
   self = [super init];
   if (self) {
       _array = [NSMutableArray array];
       _concurrentQuene = dispatch_queue_create("com.qiuxuewei.XWNetworkHelper.concurrentQuene", DISPATCH_QUEUE_CONCURRENT);
   }
   return self;
}

- (void)addObject:(id)anObject {
   dispatch_barrier_async(self.concurrentQuene, ^{
       [self.array addObject:anObject];
   });
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index {
   dispatch_barrier_async(self.concurrentQuene, ^{
       [self.array insertObject:anObject atIndex:index];
   });
}

- (void)removeLastObject {
   dispatch_barrier_async(self.concurrentQuene, ^{
       [self.array removeLastObject];
   });
}

- (void)removeObject:(NSObject *)anObject {
    if (!anObject) {
        return;
    }
    dispatch_barrier_async(self.concurrentQuene, ^{
        [self.array removeObject:anObject];
    });
}

- (void)removeAllObjects {
    dispatch_barrier_async(self.concurrentQuene, ^{
        [self.array removeAllObjects];
    });
}

- (void)removeObjectAtIndex:(NSUInteger)index {
   dispatch_barrier_async(self.concurrentQuene, ^{
       [self.array removeObjectAtIndex:index];
   });
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
   dispatch_barrier_async(self.concurrentQuene, ^{
       [self.array replaceObjectAtIndex:index withObject:anObject];
   });
}

- (id)objectAtIndex:(NSUInteger)index {
   __block id item = nil;
   dispatch_sync(self.concurrentQuene, ^{
       if (index <= self.array.count - 1) {
           item = [self.array objectAtIndex:index];
       }
   });
   return item;
}
- (nullable id)getFirstObject {
   __block id item = nil;
   dispatch_sync(self.concurrentQuene, ^{
       if (self.array.count > 0) {
           item = [self.array objectAtIndex:0];
       }
   });
   return item;
}
- (nullable id)getLastObject {
   __block id item = nil;
   dispatch_sync(self.concurrentQuene, ^{
       NSUInteger size = self.array.count;
       if (size > 0) {
           item = self.array[size - 1];
       }
   });
   return item;
}

- (void)enumerateObjectsUsingBlock:(void (NS_NOESCAPE ^)(id obj, NSUInteger idx, BOOL *stop))block {
    [self.array enumerateObjectsUsingBlock:block];
}

@end
