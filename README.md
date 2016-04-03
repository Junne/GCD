
#GCD的使用

多线程中GCD(Grand Central Dispatch)是我们比较常用,今天对于其的常见用法做以总结.  
 
* Dispatch Queue的种类一共有两种:   

   1. Serial Dispatch Queue
   2. Concurrent Dispatch Queue   

即串行和并行队列.当为串行队列时，加入到队列的任务需要等待上一个执行完才进行下一个,而并行队列时无需等待即可紧接着执行下一个任务.   
创建一个串行队列:    

```
    dispatch_queue_t mySerialDispatchQueue = dispatch_queue_create("io.github.junne.serialDispatchQueue", NULL);
    dispatch_queue_t mySerialDispatchQueue = dispatch_queue_create("io.github.junne.serialDispatchQueue", DISPATCH_QUEUE_SERIAL);
```

这里创建队列的第二个参数,NULL等同于DISPATCH_QUEUE_SERIAL.   
创建一个并行队列:   

```
    dispatch_queue_t myConcurrentDispatchQueue = dispatch_queue_create("io.github.junne.concurrentDispatchQueue", DISPATCH_QUEUE_CONCURRENT);
```   

* 系统提供的队列
  1. Main Dispatch Queue(Serial Dispatch Queue)  
  2. Global Dispatch Queue(Concurrent Dispatch Queue)  
其中追加到Main Dispatch Queue的处理在主线程的Runloop执行,一般用于UI更新等必须在主线程进行的操作.而Global Dispatch Queue相当于系统为我们用dispatch_queue_create生成的一个Concurrent Dispatch Queue,我们可以将一些多线程操作追加到这个队列中.   
Global Dispatch Queue有四个执行优先级. High Priority、Default Priority、Low Priority和Background Priority,创建方法为:   

```
    dispatch_queue_t globalDispatchQueueHigh        = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_queue_t globalDispatchQueueDefault     = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t globalDispatchQueueLow         = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_queue_t globalDispatchQueueBackgroungn = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
```

* dispatch_set_target_queue    
dispatch_queue_create创建的不论是串行还是并行队列,都使用与默认优先级的Global Dispatch Queue相同的执行优先级的线程.  

```
    dispatch_queue_t mySerialDispatchQueue = dispatch_queue_create("io.github.junne.serialTestDispatchQueue", NULL);
    dispatch_queue_t globalDispatchQueueBackgroud = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_set_target_queue(mySerialDispatchQueue, globalDispatchQueueBackgroud);
    dispatch_async(mySerialDispatchQueue, ^{
        NSLog(@"mySerialDispatchQueue");
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"Default Priority");
    });
```
执行顺序为先Default Priority后mySerialDiapatchQueue. 

* dispatch_after  
一般可用于延迟多少时间后将一些任务添加到队列,经常用于延后执行操作:  

```
    NSLog(@"dispatchAfter One");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"dispatchAfter Two");
    });
```
上述代码用来延迟三秒后执行打印dispatchAfter Two.   

* Dispatch Group
当想要队列中追加的操作处理全部结束时再进行某项操作时,可以使用一个Serial Dispatch Queue将想要执行的操作追加到最后即可.但当使用并行队列或者多个Dispatch Queue时可以使用Dispatch Group:  

```
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
```
当group里面的操作都完成时就会调用dispatch_group_notify里面的操作.  

* dispatch_barrier_async
当访问数据库时可以用Serial Dispatch Queue来避免数据竞争.但当想要高效地并行访问数据库时可以使用dispatch_barrier_async:  

```
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
```
程序会在执行dispatch_barrier_async之前,完成队列中的所有操作,继而执行barrier里面的内容,当barrier里面的内容执行完毕后再去执行之后的内容.   

* dispatch_sync  
dispatch_async中的async意味着asynchronous即非同步,就是将block非同步地追加到指定的Dispatch Queue中,不做任何等待.   
dispatch_sync意味着synchronous即同步,就是将block同步地追加到指定的Dispatch Queue中,在追加结束之前,会一直等待.  
dispatch_sync稍有不慎就会引发死锁:   

```
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_sync(mainQueue, ^{
        NSLog(@"Ha ha ha ha...");
    });
```
在主线程中执行指定的block,并等待其结束，而主线程中这在执行这些源代码,因此无法执行追加到Main Dispatch Queue的Block.   

* dispatch_apply
dispatch_apply是dispatch_sync和Dispatch Group的关联API.此函数按指定的次数将block追加到制定的队列中,并等待全部处理结束: 

```
    NSArray *testArray = @[@"first",@"second",@"third",@"fourth",@"fifth"];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply([testArray count], queue, ^(size_t index) {
        NSLog(@"%zu: %@", index, [testArray objectAtIndex:index]);
    });
    NSLog(@"TestApple Done");
```

* dispatch_suspend && dispatch_resume
当我们希望不执行已追加队列中的操作时,只要挂起Dispatch Queue即可,当需要时在恢复即可:   

```
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSLog(@"Suspend Start");
        dispatch_suspend(queue);
        NSLog(@"Susupend");
        sleep(2);
        dispatch_resume(queue);
        NSLog(@"Resume");
    });
```

* Dispatch Semaphore
直接上例子:

```
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
```

* dispatch_once
用来保证在应用程序中只执行一次指定处理的API.常用来创建单例:

```
    static ViewController *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ViewController alloc] init];
    });
    return instance;
```

参考及拓展阅读:  
* Objective-C高级编程(iOS与OS X多线程管理和内存管理)  
* [菜鸟不要怕,看一眼,你就会用GCD,带你装逼带你飞](http://pingguohe.net/2016/03/07/GCD-is-so-easy.html)
* [细说GCD（Grand Central Dispatch）如何用](https://github.com/ming1016/study/wiki/细说GCD（Grand-Central-Dispatch）如何用)  
* [谈iOS多线程（NSThread、NSOperation、GCD）编程](https://github.com/minggo620/iOSMutipleThread)  
* [Grand Central Dispatch (GCD) Reference](https://developer.apple.com/library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/index.html#//apple_ref/doc/uid/TP40008079)