context("makeSingleObjectiveFunction")

test_that("makeSingleObjectiveFunction", {
	name = "Test function"
	description = "Test function description"
	tags = c("unimodal", "separable")
	par.set = makeParamSet(
		makeNumericParam("x1", lower = -5, upper = 5),
		makeNumericParam("x2", lower = -5, upper = 5)
	)
	fn = function(x) sum(x^2)
	fn = makeSingleObjectiveFunction(
		name = name,
    id = "id",
		description = description,
		tags = tags,
		fn = fn,
		par.set = par.set,
		global.opt.params = list(x1 = 0, x2 = 0),
    local.opt.params = data.frame(x1 = c(-2, 1), x2 = c(3, 4)),
		constraint.fn = function(x) {
			sum(x) < 1
		}
	)
	expect_true(isSmoofFunction(fn))
	expect_false(isNoisy(fn))
  expect_true(attr(fn, "minimize"))
  expect_false(isVectorized(fn))
	expect_equal(name, getName(fn))
  expect_equal("id", getID(fn))
	expect_equal(description, getDescription(fn))
	expect_equal(length(getTags(fn)), 2L)
	expect_equal(length(setdiff(getTags(fn), getAvailableTags())), 0L)
	expect_output(print(fn), ".*Single.*")
	expect_equal(getNumberOfParameters(fn), 2L)
	expect_is(getParamSet(fn), "ParamSet")
	expect_equal(getNumberOfObjectives(fn), 1L)
	expect_true(hasConstraints(fn))
	expect_true(hasOtherConstraints(fn))
	expect_true(hasBoxConstraints(fn))
	expect_true(hasGlobalOptimum(fn))
  expect_true(hasLocalOptimum(fn))
	global.optimum = getGlobalOptimum(fn)
	expect_true(!is.null(global.optimum))
	expect_is(global.optimum, "list")
	expect_equal(global.optimum[["param"]][["x1"]], 0)
	expect_equal(global.optimum[["param"]][["x1"]], 0)
	expect_equal(global.optimum[["value"]], 0)
  expect_equal(global.optimum[["is.minimum"]], TRUE)

  local.optima = getLocalOptimum(fn)
  expect_is(local.optima, "list")
  expect_equal(nrow(local.optima$param), 2L)
  expect_true(setequal(local.optima$value, c(13, 17)))
  expect_equal(local.optima[["is.minimum"]], TRUE)

	# global opt params out of bounds
	expect_error(makeSingleObjectiveFunction(name, fn, par.set = par.set, global.opt.params = list(x1 = -10, x2 = 100)))

	# params not named properly
	expect_error(makeSingleObjectiveFunction(name, fn, par.set = par.set, global.opt.params = list(alice = 0, bob = 0)))

})

test_that("global optimum is provided properly", {

	generateTestFunction = function(global.opt.params) {
		fn = makeSingleObjectiveFunction(
			name = "My test function",
			fn = function(x) x^2,
			par.set = makeParamSet(
				makeNumericParam("num1", lower = -10, upper = 10)
			),
			global.opt.params = global.opt.params
		)
	}

	expect_error(generateTestFunction(list(num1 = 100)))
	expect_is(generateTestFunction(c(num1 = 0)), "smoof_function")
	expect_is(generateTestFunction(0), "smoof_function")
})

test_that("variants of global.opt.params work well", {

	generateTestFunction = function(global.opt.params) {
		fn = makeSingleObjectiveFunction(
			name = "My test function",
			fn = function(x) sum(x^2),
			par.set = makeParamSet(
				makeNumericParam("x1", lower = -10, upper = 10),
				makeNumericParam("x2", lower = -10, upper = 10)
			),
			global.opt.params = global.opt.params
		)
	}

	expectIsCorrect = function(fn, n.opts = 1L) {
		expect_is(fn, "smoof_function")
		go = getGlobalOptimum(fn)
		expect_equal(go$value, 2)
		expect_is(go$param, "data.frame")
		expect_equal(nrow(go$param), n.opts)
	}

	fn = generateTestFunction(c(x1 = 1, x2 = 1))
	expectIsCorrect(fn)
	fn = generateTestFunction(list(x1 = 1, x2 = 1))
	expectIsCorrect(fn)
	fn = generateTestFunction(matrix(c(1, 1, -1, -1), ncol = 2, byrow = TRUE))
	expectIsCorrect(fn, n.opts = 2L)
	fn = generateTestFunction(data.frame(x1 = c(1, 1, -1), x2 = c(1, -1, -1)))
	expectIsCorrect(fn, n.opts = 3L)
})

test_that("noisy functions work well", {
  fn = makeSingleObjectiveFunction(
    fn = function(x) {
      sum(x^2) + rnorm(1, sd = 0.01)
    },
    fn.mean = function(x) {
      sum(x^2)
    },
    noisy = TRUE,
    par.set = makeNumericParamSet("x", len = 1L, lower = -5, upper = 5)
  )
  expect_true(isNoisy(fn))
  fn.mean = getMeanFunction(fn)
  expect_true(is.function(fn.mean))
  expect_true(is.function(attr(fn, "fn")))

  # check if mean function is really the mean function (#90)
  rnds = runif(10, min = -5, max = 5)
  expect_true(all(sapply(rnds, fn.mean) == rnds^2))
  expect_true(is.numeric(sapply(runif(10), fn.mean)))
})
