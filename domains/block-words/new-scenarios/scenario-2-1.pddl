(define (problem block_words)
	(:domain block-words)
	(:objects
		d r a w p e - block
	)
	(:init
		(handempty)

		(clear w)
		(on w e)
		(ontable e)

		(clear r)
		(ontable r)

		(clear a)
		(on a d)
		(ontable d)

		(clear p)
		(ontable p)

	)
	(:goal (and
		;; pear
		(clear p) (ontable r) (on a r) (on e a) (on p e)
	))
)
