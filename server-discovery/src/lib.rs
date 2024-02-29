use std::{
    sync::{mpsc, Arc, Mutex}, 
    thread,
};
pub struct ThreadPool {
    size: usize,
    workers: Vec<Worker>,
    sender: Option<mpsc::Sender<Job>>,
}


#[derive(Debug)]
pub enum PoolError {
    PoolCreationError,
}

type Job = Box<dyn FnOnce() + Send + 'static>;

impl ThreadPool {
    /// Create a new ThreadPool.
    ///
    /// The size is the number of threads in the pool.
    ///
    /// # Panics
    ///
    /// The `new` function will panic if the size is zero
    pub fn build(size: usize) -> Result<ThreadPool, PoolError> {
        if size <= 0 {
            return Err(PoolError::PoolCreationError);
        }

        let (sender, receiver) = mpsc::channel();

        let mut workers = Vec::with_capacity(size);

        // Atomic reference counter - allows having several references to the same item
        // in a shared environment.
        // Mutex allows atomic access to the item (only one can read or write at a time)
        let receiver = Arc::new(Mutex::new(receiver));

        for id in 0..size {
            // we need to clone the atomic reference for each thread
            workers.push(Worker::new(id, Arc::clone(&receiver)));
            // create some threads
        }

        Ok(ThreadPool { size, workers, sender: Some(sender)})
    }

    pub fn execute<F>(&self, f: F)
    where
        F: FnOnce() + Send + 'static,
    {
        let job = Box::new(f);
        self.sender.as_ref().unwrap().send(job).unwrap();
    }
}

// Shutting down gracefully
impl Drop for ThreadPool {
    fn drop(&mut self) {
        drop(self.sender.take());

        for worker in &mut self.workers {
            println!("Shutting down worker {}", worker.id);
            // the take method takes ownership of the inner value in option, and leaves
            // a None value there
            if let Some(thread) = worker.thread.take() {
                thread.join().unwrap();
            }
        }
    }
}


struct Worker {
    id: usize,
    // we used an option here since for shuting down, we can’t call join because we only have 
    // a mutable borrow of each worker and join takes ownership of its argument
    thread: Option<thread::JoinHandle<()>>,
}

impl Worker {
    fn new(id: usize, receiver: Arc<Mutex<mpsc::Receiver<Job>>>) -> Worker {
        let thread = thread::spawn(move || loop {
            let message = receiver.lock().unwrap().recv();

            match message {
                Ok(job) => {
                    println!("Worker {id} got a job; executing.");
                    job();
                }
                Err(_) => {
                    println!("Worker {id} disconnected; shutting down");
                    break;
                }
            }
        });

        Worker { 
            id, 
            thread: Some(thread) 
        }
    }
}

