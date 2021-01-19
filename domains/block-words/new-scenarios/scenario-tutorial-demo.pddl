(define (problem block_words)
	(:domain block-words)
	(:objects
		d r a w p e - block
	)
	(:init
		(handempty)

		(clear e)
		(on e p)
		(ontable p)

		(clear w)
		(on w a)
		(ontable a)

		(clear r)
		(on r d)
		(ontable d)

	)
	(:goal (and
		;; ear
		(clear e) (ontable r) (on a r) (on e a)
	))
)
