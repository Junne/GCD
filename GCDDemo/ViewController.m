//
//  ViewController.m
//  GCDDemo
//
//  Created by Junne on 3/28/16.
//  Copyright © 2016 Junne. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self testDispatchSync];
//    [self creatSerialDispatchQueue];
//    [self creatConcurrentDispatchQueue];
//    [self globalDispatchType];
//    [self testChangeQueuePriority];
//    [self testDispatchAfter];
//    [self testDispatchGroup];
//    [self testDispatchBarrierAsync];
////    [self testDispatchSync];
//    [self testDispatchApply];
//    [self testDispatchSuspendAndResume];
    [self testDispatchSemaphore];

    // Do any additional setup after loading the view, typically from a nib.
}

- (void)creatSerialDispatchQueue
{
    dispatch_queue_t mySerialDispatchQueue = dispatch_queue_create("io.github.junne.serialDispatchQueue", NULL);
//    dispatch_queue_t mySerialDispatchQueue = dispatch_queue_create("io.github.junne.serialDispatchQueue", DISPATCH_QUEUE_SERIAL);
    NSLog(@"mySerialDispatchQueue = %@", mySerialDispatchQueue);
    
}

- (void)creatConcurrentDispatchQueue
{
    dispatch_queue_t myConcurrentDispatchQueue = dispatch_queue_create("io.github.junne.concurrentDispatchQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(myConcurrentDispatchQueue, ^{
        NSLog(@"Hello World!");
    });
//    dispatch_release(myConcurrentDispatchQueue);
    NSLog(@"myConcurrentDispatchQueue = %@", myConcurrentDispatchQueue);
}

- (void)globalDispatchType
{
    dispatch_queue_t globalDispatchQueueHigh        = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_queue_t globalDispatchQueueDefault     = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t globalDispatchQueueLow         = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_queue_t globalDispatchQueueBackgroungn = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(globalDispatchQueueBackgroungn, ^{
        NSLog(@"First");
    });
    
    dispatch_async(globalDispatchQueueLow, ^{
        NSLog(@"Second");
    });
    
    dispatch_async(globalDispatchQueueDefault, ^{
        NSLog(@"Third");
    });
    
    dispatch_async(globalDispatchQueueHigh, ^{
        NSLog(@"Fourth");
    });
}

- (void)testChangeQueuePriority
{
    dispatch_queue_t mySerialDispatchQueue = dispatch_queue_create("io.github.junne.serialTestDispatchQueue", NULL);
    dispatch_queue_t globalDispatchQueueBackgroud = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_set_target_queue(mySerialDispatchQueue, globalDispatchQueueBackgroud);
    dispatch_async(mySerialDispatchQueue, ^{
        NSLog(@"mySerialDispatchQueue");
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"Default Priority");
    });
}

- (void)testDispatchAfter
{
//    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC);
    NSLog(@"dispatchAfter First");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"dispatchAfter Second");
    });
}

- (void)testDispatchGroup
{
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, globalQueue, ^{
        NSLog(@"Group First");
    });
    dispatch_group_async(group, globalQueue, ^{
        NSLog(@"Group Second");
    });
    dispatch_group_async(group, globalQueue, ^{
        NSLog(@"Group Third");
    });
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"Group All Done");
    });
    
//    long result = dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)));
//    if (result == 0) {
//        NSLog(@"Group All Done");
//    } else {
//        NSLog(@"Group Not All Done");
//    }
    
}

- (void)testDispatchBarrierAsync
{
    dispatch_queue_t queue = dispatch_queue_create("io.guthub.junne.barrier", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSLog(@"Reading First");
    });
    dispatch_async(queue, ^{
        NSLog(@"Reading Second");
    });
    dispatch_async(queue, ^{
        NSLog(@"Reading Third");
    });
    dispatch_barrier_async(queue, ^{
        NSLog(@"Writing First");
    });
    dispatch_async(queue, ^{
        NSLog(@"Reading Fourth");
    });
    dispatch_async(queue, ^{
        NSLog(@"Reading Fifth");
    });    dispatch_async(queue, ^{
        NSLog(@"Reading Sixth");
    });
}

- (void)testDispatchSync
{
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_sync(mainQueue, ^{
        NSLog(@"Ha ha ha ha...");
    });
}

- (void)testDispatchApply
{
    NSArray *testArray = @[@"first",@"second",@"third",@"fourth",@"fifth"];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply([testArray count], queue, ^(size_t index) {
        NSLog(@"%zu: %@", index, [testArray objectAtIndex:index]);
    });
    NSLog(@"TestApple Done");
}

- (void)testDispatchSuspendAndResume
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSLog(@"Suspend Start");
        dispatch_suspend(queue);
        NSLog(@"Susupend");
        sleep(2);
        dispatch_resume(queue);
        NSLog(@"Resume");
    });
}

- (void)testDispatchSemaphore
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < 10; i++) {
        dispatch_async(queue, ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            [mutableArray addObject:[NSNumber numberWithInt:i]];
            dispatch_semaphore_signal(semaphore);
        });
    }
    NSLog(@"mutableArray = %@", mutableArray);
}

+ (ViewController *)creatInstance
{

    static ViewController *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ViewController alloc] init];
    });
    return instance;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
