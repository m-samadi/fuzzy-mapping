#**************************************************************************
# fuzzy.py
#
# Perform task-to-thread mapping in OpenMP using fuzzy decision making
#**************************************************************************
 # Copyright 2024 Instituto Superior de Engenharia do Porto
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #              http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 #**************************************************************************
import numpy as np
from operator import itemgetter
import func

# Global variables #
task_stack = [] # Task stack
alloc_queue = [] # Allocation queues of the threads
exec_queue = [] # Execution queues of the threads
curr_thr = -1 # Current thread
comp_tasks_cnt = 0 # Number of completed tasks

num_of_task_sf = 0 # Shape factor for the number of tasks
num_of_task_lb = 0 # Lower bound for the number of tasks
num_of_task_ub = 0 # Upper bound for the number of tasks
num_of_task_u = [] # Universe of discourse for the number of tasks
tot_exe_time_sf = 0 # Shape factor for the total execution time
tot_exe_time_lb = 0 # Lower bound for the total execution time
tot_exe_time_ub = 0 # Upper bound for the total execution time
tot_exe_time_u = [] # Universe of discourse for the total execution time
exe_time_sf = 0 # Shape factor for the execution time
exe_time_lb = 0 # Lower bound for the execution time
exe_time_ub = 0 # Upper bound for the execution time
exe_time_u = [] # Universe of discourse for the execution time
wait_time_sf = 0 # Shape factor for the waiting time
wait_time_lb = 0 # Lower bound for the waiting time
wait_time_ub = 0 # Upper bound for the waiting time
wait_time_u = [] # Universe of discourse for the waiting time
u_sel_rate = np.round(np.arange(0, 1 + 0.01, 0.01).tolist(), 2) # Universe of discourse for the selection rate

# Read the models from file #
def read_model(model_name):
	model = []

	if model_name == 'model1':
		with open('model/model1.dat') as f:
			model_ln = f.readlines()
	elif model_name == 'model2':
		with open('model/model2.dat') as f:
			model_ln = f.readlines()
	else:
		with open('model/model3.dat') as f:
			model_ln = f.readlines()
	f.close()

	for i in range(len(model_ln)):
		ln = model_ln[i]
		ln = ln.replace('\n', '')
		ln_sp = ln.split(',')
		ln_arr = []
		for j in range(len(ln_sp)):
			ln_arr.append(ln_sp[j])
		
		model.append(ln_arr)

	return model

# Perform fuzzification using triangular membership function #
def fuzzification(universe_of_discourse, center, width):
    set = [] # Fuzzy set
    for i in range(len(universe_of_discourse)):
        if abs(center - universe_of_discourse[i]) > width / 2:
            set.append(0)
        else:
             set.append(1 - 2 * abs(center - universe_of_discourse[i]) / width)
    
    return set

# Perform inference using the Max-Min function #
def inference(model, input):
    output = [] # Output fuzzy set
    for i in range(np.shape(model)[1]):
        m = 0
        for j in range(np.shape(model)[0]):
            m = max(min(float(input[j]), float(model[j][i])), m)
        
        output.append(m)

    return (output)

# Perform defuzzification using the center-of-gravity method #
def defuzzification(universe_of_discourse, fuzzy_set):
	s1 = 0
	s2 = 0
	for i in range(len(universe_of_discourse)):
		s1 += fuzzy_set[i] * universe_of_discourse[i]
		s2 += fuzzy_set[i]
	
	if s2 == 0:
		return 0
	else:
		return s1 / s2

# Select an allocation queue using one of the allocation algorithms #
def allocation(num_threads, alloc_alg, model):
	global alloc_queue, curr_thr

	# Select the queue using Controller 1 #
	if alloc_alg == 'CONT1':
		sel_rate = [] # Selection rate

		for i in range(num_threads):
			# Determine number of tasks in the queues #
			num_of_task = len(alloc_queue[i]) # Number of tasks

			if num_of_task < num_of_task_lb:
				num_of_task = num_of_task_lb
			if num_of_task > num_of_task_ub:
				num_of_task = num_of_task_ub

			# Perform the data collection #
			# file = open("num_task.txt", "a+")
			# file.write(str(num_of_task) + "\n")
			# file.close()

			# Specify total execution time of the tasks #
			tot_exe_time = 0 # Total execution time
			for j in range(len(alloc_queue[i])):
				tot_exe_time += alloc_queue[i][j].et

			if tot_exe_time < tot_exe_time_lb:
				tot_exe_time = tot_exe_time_lb
			if tot_exe_time > tot_exe_time_ub:
				tot_exe_time = tot_exe_time_ub

			# Perform the data collection #
			# file = open("tot_exe_time.txt", "a+")
			# file.write(str(tot_exe_time) + "\n")
			# file.close()

			# Calculate selection rate for the queues using the inference process #
			mu_num_of_task = fuzzification(num_of_task_u, num_of_task, num_of_task_sf)
			mu_tot_exe_time = fuzzification(tot_exe_time_u, tot_exe_time, tot_exe_time_sf)
			mu_sel_rate = inference(model, np.minimum(mu_num_of_task, mu_tot_exe_time))
			sel_rate.append(defuzzification(u_sel_rate, mu_sel_rate))

			# Select the queue with the highest selection rate #
			sel_id = 0
			for i in range(1, len(sel_rate)):
				if sel_rate[i] > sel_rate[sel_id]:
					sel_id = i
		
		return sel_id
	
	# Select the queue using the round-robin (RR) method #
	else:
		if curr_thr < num_threads - 1:
			curr_thr += 1
		else:
			curr_thr = 0

		return curr_thr

# Choose a task from the allocation queue using one of the dispatching algorithms #
def dispatching(sel_tasks, disp_alg, model, t):
	# Select the task using Controller 2 or Controller 3 #
	if disp_alg == 'CONT2' or disp_alg == 'CONT3':
		sel_rate = [] # Selection rate

		for i in range(len(sel_tasks)):
			# Determine execution time of the task #
			exe_time = sel_tasks[i].et # Execution time

			if exe_time < exe_time_lb:
				exe_time = exe_time_lb
			if exe_time > exe_time_ub:
				exe_time = exe_time_ub

			# Specify waiting time of the task #
			wait_time = t - sel_tasks[i].a_time # Waiting time

			if wait_time < wait_time_lb:
				wait_time = wait_time_lb
			if wait_time > wait_time_ub:
				wait_time = wait_time_ub

			# Perform the data collection #
			# file = open("wait_time.txt", "a+")
			# file.write(str(wait_time) + "\n")
			# file.close()	

			# Calculate selection rate for the task using the inference process #
			mu_exe_time = fuzzification(exe_time_u, exe_time, exe_time_sf)
			mu_wait_time = fuzzification(wait_time_u, wait_time, wait_time_sf)
			mu_sel_rate = inference(model, np.minimum(mu_exe_time, mu_wait_time))
			sel_rate.append(defuzzification(u_sel_rate, mu_sel_rate))

			# Select the task with the highest selection rate #
			sel_id = 0
			for i in range(1, len(sel_rate)):
				if sel_rate[i] > sel_rate[sel_id]:
					sel_id = i

	# Select the task using the first in, first out (FIFO) method #
	else:
		sel_id = 0

	return sel_id

# The mapping process #
def mapping(num_tasks, num_threads, task_list, alloc_alg, disp_alg):
	global task_stack, alloc_queue, exec_queue, curr_thr, comp_tasks_cnt

	# Read the models #
	if alloc_alg == 'CONT1':
		alloc_model = read_model('model1')
	else:
		alloc_model = ''

	if disp_alg == 'CONT2':
		disp_model = read_model('model2')
	elif disp_alg == 'CONT3':
		disp_model = read_model('model3')
	else:
		disp_model = ''

	t = 0 # Response time

	# Continue the mapping process while the allocation queues of the threads are not empty, as well as #
	# the execution queues of the threads include executing tasks #
	while comp_tasks_cnt < num_tasks:
		for thr_num in range(num_threads):
			# Check the execution queue of the thread #
			if bool(exec_queue[thr_num]):
				task = exec_queue[thr_num][len(exec_queue[thr_num]) - 1]

				# Check whether the execution of the task has been finished #
				if task.status == 's' and task.f_time <= t:
					task.status = 'f'

					curr_thr = thr_num
					comp_tasks_cnt += 1				

			# Check the task stack and add the ready tasks to the allocation queues #
			# This process is done just by the master thread #
			if thr_num == 0:
				remove_list = []
				for i in range(len(task_stack)):
					# Add the ready tasks to the allocation queues if there are not any data dependencies, or #
					# there are any data dependencies but the related tasks are finished #
					if task_stack[i].dep == None or func.check_dep(task_list, task_stack[i].dep) == True:
						# Select an allocation queue from the list of queues #
						thread_id = allocation(num_threads, alloc_alg, alloc_model)

						# Append the task to the selected queue #
						alloc_queue[thread_id].append(task_stack[i])
						task_stack[i].a_time = t						

						remove_list.append(task_stack[i])

				# Remove the tasks, which were processed, from the task stack #
				for j in range(len(remove_list)):
					task_stack.remove(remove_list[j])

			# Check whether the thread is idle #
			if not bool(exec_queue[thr_num]) or exec_queue[thr_num][len(exec_queue[thr_num]) - 1].status == 'f':
				# Check the allocation queue of the thread and dispatch one of the tasks (if any) to the thread #
				if bool(alloc_queue[thr_num]):
					# Choose one of the tasks from the allocation queue #
					sel_task = alloc_queue[thr_num][dispatching(alloc_queue[thr_num], disp_alg, disp_model, t)]

					# Dispatch the task to the thread #
					exec_queue[thr_num].append(sel_task)
					task = exec_queue[thr_num][len(exec_queue[thr_num]) - 1]

					task.status = 's'
					task.s_time = t
					task.f_time = t + task.et

					# Remove the task from the allocation queue #
					alloc_queue[thr_num].remove(sel_task)

		t += 1000000

	return t

# The main function #
def execute(num_tasks, num_threads, task_list, deadline, alloc_alg, disp_alg, graphic_result, bench_name):
	global task_stack, alloc_queue, exec_queue, comp_tasks_cnt, num_of_task_sf, num_of_task_lb,\
		num_of_task_ub, num_of_task_u, tot_exe_time_sf, tot_exe_time_lb, tot_exe_time_ub, tot_exe_time_u,\
		exe_time_sf, exe_time_lb, exe_time_ub, exe_time_u, wait_time_sf, wait_time_lb, wait_time_ub,\
		wait_time_u

	# Create the task stack and append the tasks to this list #
	task_stack = []
	for i in range(num_tasks):
		task_stack.append(task_list[i])

	# Create an allocation queue for each thread #
	alloc_queue = []
	for i in range(num_threads):
		alloc_queue.append([])

	# Create an execution queue for each thread #
	exec_queue = []
	for i in range(num_threads):
		exec_queue.append([])

	# Initialize the number of completed tasks #
	comp_tasks_cnt = 0

	# Set the initial parameters for the fuzzy controllers #
	if bench_name == 'axpy':
		num_of_task_sf = 15
		num_of_task_lb = 4
		num_of_task_ub = 24
		num_of_task_u = np.round(np.arange(num_of_task_lb, num_of_task_ub + 0.2, 0.2).tolist(), 2)
		tot_exe_time_sf = 98500000
		tot_exe_time_lb = 59000000
		tot_exe_time_ub = 256000000
		tot_exe_time_u = np.arange(tot_exe_time_lb, tot_exe_time_ub + 1970000, 1970000).tolist()
		exe_time_sf = 7500000
		exe_time_lb = 7000000
		exe_time_ub = 22000000
		exe_time_u = np.arange(exe_time_lb, exe_time_ub + 150000, 150000).tolist()
		wait_time_sf = 91000000
		wait_time_lb = 59000000
		wait_time_ub = 241000000
		wait_time_u = np.arange(wait_time_lb, wait_time_ub + 1820000, 1820000).tolist()
	elif bench_name == 'heat':
		num_of_task_sf = 3
		num_of_task_lb = 0
		num_of_task_ub = 4
		num_of_task_u = np.round(np.arange(num_of_task_lb, num_of_task_ub + 0.04, 0.04).tolist(), 2)
		tot_exe_time_sf = 50000000
		tot_exe_time_lb = 0
		tot_exe_time_ub = 100000000
		tot_exe_time_u = np.arange(tot_exe_time_lb, tot_exe_time_ub + 1000000, 1000000).tolist()
		exe_time_sf = 7000000
		exe_time_lb = 30000000
		exe_time_ub = 45000000
		exe_time_u = np.arange(exe_time_lb, exe_time_ub + 150000, 150000).tolist()
		wait_time_sf = 50000000
		wait_time_lb = 0
		wait_time_ub = 100000000
		wait_time_u = np.arange(wait_time_lb, wait_time_ub + 1000000, 1000000).tolist()
	elif bench_name == 'sparseLU':
		num_of_task_sf = 6
		num_of_task_lb = 2
		num_of_task_ub = 10
		num_of_task_u = np.round(np.arange(num_of_task_lb, num_of_task_ub + 0.08, 0.08).tolist(), 2)
		tot_exe_time_sf = 116000000
		tot_exe_time_lb = 0
		tot_exe_time_ub = 232000000
		tot_exe_time_u = np.arange(tot_exe_time_lb, tot_exe_time_ub + 2320000, 2320000).tolist()
		exe_time_sf = 40000000
		exe_time_lb = 0
		exe_time_ub = 80000000
		exe_time_u = np.arange(exe_time_lb, exe_time_ub + 800000, 800000).tolist()
		wait_time_sf = 70000000
		wait_time_lb = 0
		wait_time_ub = 145000000
		wait_time_u = np.arange(wait_time_lb, wait_time_ub + 1450000, 1450000).tolist()

	# Show the mapping algorithm #
	print('\n' + alloc_alg + '-' + disp_alg + '\n***********************************')
	t = mapping(num_tasks, num_threads, task_list, alloc_alg, disp_alg)

	# Calculate the results #
	response_time = t # The response time
	idle_time = sum(func.idle_time(num_threads, exec_queue, t)) # The idle time of the system
	miss_deadline = func.miss_deadline(deadline, t) # The missed deadline status of the system

	# Show the results #
	print('Response time: ' + str(response_time))
	print('Idle time: ' + str(idle_time))
	print('Missed deadline: ' + str(miss_deadline))

	# Export the scheduling of the threads #
	func.export_scheduling(num_threads, exec_queue, 'fuzzy', alloc_alg, disp_alg)

	# Draw the graphical output #
	if graphic_result == 1:
		func.graphic_result(num_threads, exec_queue, t, 'fuzzy', alloc_alg, disp_alg)

	# Return the results to the main program #
	return response_time, idle_time, miss_deadline
