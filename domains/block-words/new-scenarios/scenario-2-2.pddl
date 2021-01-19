(define (problem block_words)
	(:domain block-words)
	(:objects
		d r a w p e - block
	)
	(:init
		(handempty)

		(clear a)
		(ontable a)

		(clear e)
		(on e d)
		(ontable d)

		(clear w)
		(on w p)
		(ontable p)

		(clear r)
		(ontable r)


	)
	(:goal (and
		;; ear
		(clear e) (ontable r) (on a r) (on e a)
	))
)
