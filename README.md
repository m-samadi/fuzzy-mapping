# Task-to-thread mapping using fuzzy decision making
This simulator performs task-to-thread mapping of OpenMP-based applications using fuzzy decision making based on three fuzzy controllers. However, the other mapping methods are also developed to create comparison results.
<br/>
<br/>
## Contents of the repository
The repository contains three parts: data collection, modeling, and fuzzy mapping. The data collection part is used to collect simulation data to specify lower and upper bounds of the parameters for the fuzzy controllers. The modeling part is applied to create a model for each controller. It is carried out based on the measurement process on an NVIDIA Jetson AGX Xavier using the fuzzy mapping [1] based on the BSC LLVM compiler [2]. The fuzzy mapping part is used to execute the main simulation process.
<br/>
<br/>
## Benchmarks
Three benchmarks are provided in the simulator (placed in the "benchmark" directory), including a DOT file (that contains the task ID and data dependencies of the tasks) and a JSON file (that contains the execution times for each task). Two JSON files are provided for each benchmark, where the execution times of tasks are measured in the cases of running 4 and 8 threads. To apply them in the simulator, you may simply rename one of the files to bench_json (where bench is the name of the benchmark) before the simulation process. Note that the execution times are measured using the Extrae [3] and Papi [4] tools, as well as the JSON files are generated using a script [5] and the Paraver toolset [6].
<br/>
<br/>
Any new benchmarks can be easily added to this set and used in the simulator, following the structure of the DOT and JSON files.
<br/>
<br/>
## General specifications of the simulator
The graphs can be generated in the simulator based on the benchmarks or randomly. The task execution time is calculated using the minimum, average, or maximum function. The application deadline is determined based on the volume of graph and a random number. For each given method, the response time, missed deadline, idle time of threads, and static scheduling of tasks in threads are determined through the simulation process. Furthermore, graphical results can be generated to show the mapping of tasks. After mapping process of the graph is conducted using each algorithm, the response time, idle time, and missed deadline obtained from all the methods are exported to a file.
<br/>
<br/>
After the modeling is done using a simulator in the modeling part, the created models should be copied to the "model" directory in the fuzzy mapping part. Furthermore, since the simulator is primarily used to schedule the graphs generated based on benchmarks as well as the execution times of tasks provided using the profiling process are high, the tick (e.g., time interval) of the loop in the codes is set to 1000000 (i.e., t += 1000000) by default. However, it can be set to 1 to simulate other benchmarks or random graphs.
<br/>
<br/>
## Simulation parameters
The simulation parameters are set by default. However, they can be changed at the beginning of simulation.py before the simulation process based on requirements of the application.
<br/>
<br/>
## Graphical output
Graphical outputs can be generated at the end of the simulation by setting the "graphic_result" variable to 1. Note that Python Image Library (PIL) should be installed using the command below:
```
pip install pillow
```
Since there is a limitation in drawing the shapes in Python, if the number of tasks is high, keep this feature disabled.
<br/>
<br/>
## Execution
Before simulation, the numpy module should be installed using the command below:
```
pip install numpy
```
The simulation process runs with the following command:
```
python simulation.py
```
If the graph should be generated based on the benchmark, press 'y'; otherwise press 'n'.
<br/>
<br/>
## References
[1] M. Samadi, S. Royuela, L. M. Pinho, T. Carvalho, and E. Quiñones, "Time-Predictable Task-to-Thread Mapping in Multi-Core Processors," Journal of Systems Architecture, vol. 148, Article ID 103068, March 2024.
<br/>
[2] Barcelona Supercomputing Center, "BSC LLVM," November 2024. https://gitlab.bsc.es/ampere-sw/wp2/llvm/
<br/>
[3] Barcelona Supercomputing Center, "Extrae," November 2024. https://tools.bsc.es/extrae/
<br/>
[4] Innovative Computing Laboratory, University of Tennessee, "Performance Application Programming Interface, PAPI," November 2024. https://icl.utk.edu/papi/index.html/
<br/>
[5] Barcelona Supercomputing Center, "TDG instrumentation," November 2024. https://gitlab.bsc.es/ampere-sw/wp2/tdg-instrumentation-script/
<br/>
[6]	A. Munera, S. Royuela, G. Llort, E. Mercadal, F. Wartel, and E. Quiñones, "Experiences on the characterization of parallel applications in embedded systems with extrae/paraver," in Proc. of the 49th Int. Conference on Parallel Processing (ICPP '20), Edmonton, AB, Canada, pp. 1–11, August 17–20, 2020.
