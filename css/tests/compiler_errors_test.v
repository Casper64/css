import benchmark
import os
import rand
import runtime
import term
import time
import v.util.diff

const test_program_name = 'test_program.v'

const turn_off_vcolors = os.setenv('VCOLORS', 'never', true)

const github_job = os.getenv('GITHUB_JOB')

struct TaskDescription {
	dir              string
	result_extension string
	path             string
	program          string
mut:
	is_error          bool
	is_skipped        bool
	expected          string
	expected_out_path string
	found___          string
	took              time.Duration
	cli_cmd           string
}

struct Tasks {
	parallel_jobs int // 0 is using VJOBS, anything else is an override
	label         string
mut:
	all []TaskDescription
}

fn test_all() {
	os.chdir(@VMODROOT)!
	parser_dir := 'css/parser/tests'
	checker_dir := 'css/checker/tests'

	mut tasks := Tasks{
		label: 'all tests'
	}

	parser_tests := get_tests_in_dir(parser_dir)
	checker_tests := get_tests_in_dir(checker_dir)
	tasks.add(parser_dir, '.out', parser_tests, 'css/parser/tests/test_program.v')
	tasks.add(checker_dir, '.out', checker_tests, 'css/checker/tests/test_program.v')

	tasks.run()
}

fn (mut tasks Tasks) add(dir string, result_extension string, tests []string, program string) {
	program_id := rand.ulid()
	exec_path := os.join_path(os.vtmp_dir(), 'css_test_${program_id}')
	eprintln('EXECUTING: ${exec_path}')
	mut res := os.execute('${os.quoted_path(@VEXE)} ${program} -o ${exec_path}')
	dump(res)

	for path in tests {
		tasks.all << TaskDescription{
			program: exec_path
			dir: dir
			result_extension: result_extension
			path: os.join_path_single(dir, path)
		}
	}
}

fn bstep_message(mut bench benchmark.Benchmark, label string, msg string, sduration time.Duration) string {
	return bench.step_message_with_label_and_duration(label, msg, sduration)
}

// process an array of tasks in parallel, using no more than vjobs worker threads
fn (mut tasks Tasks) run() {
	if tasks.all.len == 0 {
		return
	}
	vjobs := if tasks.parallel_jobs > 0 { tasks.parallel_jobs } else { runtime.nr_jobs() }
	mut bench := benchmark.new_benchmark()
	bench.set_total_expected_steps(tasks.all.len)
	mut work := chan TaskDescription{cap: tasks.all.len}
	mut results := chan TaskDescription{cap: tasks.all.len}

	for i in 0 .. tasks.all.len {
		work <- tasks.all[i]
	}
	work.close()
	if github_job == '' {
		println('')
	}
	for _ in 0 .. vjobs {
		spawn work_processor(work, results)
	}

	mut line_can_be_erased := true
	mut total_errors := 0
	for _ in 0 .. tasks.all.len {
		mut task := TaskDescription{}
		task = <-results
		bench.step()
		if task.is_error {
			total_errors++
			bench.fail()
			eprintln(bstep_message(mut bench, benchmark.b_fail, task.path, task.took))
			println('============')
			println('failed cmd: ${task.cli_cmd}')
			println('expected_out_path: ${task.expected_out_path}')
			println('============')
			println('expected:')
			println(task.expected)
			println('============')
			println('found:')
			println(task.found___)
			println('============\n')
			diff_content(task.expected, task.found___)
			line_can_be_erased = false
		} else {
			bench.ok()
			assert true
			if github_job == '' {
				// local mode:
				if line_can_be_erased {
					term.clear_previous_line()
				}
				println(bstep_message(mut bench, benchmark.b_ok, task.path, task.took))
			}
			line_can_be_erased = true
		}
	}
	bench.stop()
	eprintln(term.h_divider('-'))
	eprintln(bench.total_message(tasks.label))
	if total_errors != 0 {
		exit(1)
	}
}

// a single worker thread spends its time getting work from the `work` channel,
// processing the task, and then putting the task in the `results` channel
fn work_processor(work chan TaskDescription, results chan TaskDescription) {
	for {
		mut task := <-work or { break }
		sw := time.new_stopwatch()
		task.execute()
		task.took = sw.elapsed()
		results <- task
	}
}

// actual processing; Note: no output is done here at all
fn (mut task TaskDescription) execute() {
	if task.is_skipped {
		return
	}
	css_file := task.path
	strict_arg := if css_file.ends_with('_strict.css') {
		' --strict'
	} else {
		''
	}
	cli_cmd := '${task.program} ${css_file}${strict_arg}'
	res := os.execute(cli_cmd)
	expected_out_path := css_file.replace('.css', '') + task.result_extension
	task.expected_out_path = expected_out_path
	task.cli_cmd = cli_cmd

	mut expected := os.read_file(expected_out_path) or {
		eprintln('FAILED!!! ${css_file}')
		panic(err)
	}
	task.expected = term.strip_ansi(clean_line_endings(expected))
	task.found___ = term.strip_ansi(clean_line_endings(res.output))

	if task.expected != task.found___ {
		task.is_error = true
	}
}

fn clean_line_endings(s string) string {
	mut res := s.trim_space()
	res = res.replace(' \n', '\n')
	res = res.replace(' \r\n', '\n')
	res = res.replace('\r\n', '\n')
	res = res.trim('\n')
	return res
}

fn diff_content(expected string, found string) {
	diff_cmd := diff.find_working_diff_command() or { return }
	println(term.bold(term.yellow('diff: ')))
	println(diff.color_compare_strings(diff_cmd, rand.ulid(), expected, found))
	println('============\n')
	eprintln('got ${found}')
}

fn get_tests_in_dir(dir string) []string {
	eprintln('tests ${dir} from ${os.getwd()}')
	files := os.ls(dir) or { panic(err) }
	mut tests := files.clone()
	tests = files.filter(it.ends_with('.css'))
	tests.sort()
	return tests
}
