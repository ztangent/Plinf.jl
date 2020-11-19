(define (problem block_words)
	(:domain block-words)
	(:objects
		d r a w p e - block
	)
	(:init
		(handempty)

		(clear r)
		(ontable r)

		(clear a)
		(on a e)
		(on e p)
		(ontable p)

		(ontable d)
		(clear d)

		(ontable w)
		(clear w)
	)
	(:goal (and
		;; wear
		(clear w) (ontable r) (on w e) (on e a) (on a r)
	))
)
