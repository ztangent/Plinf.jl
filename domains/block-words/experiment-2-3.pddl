(define (problem block_words)
	(:domain block-words)
	(:objects
		d r a w p e - block
	)
	(:init
		(handempty)

		(clear p)
		(ontable p)

		(clear r)
		(on r a)
		(on a w)
		(ontable w)

		(clear e)
		(on e d)
		(ontable d)
	)
	(:goal (and
		;; reap
		(clear r) (ontable p) (on r e) (on e a) (on a p)
	))
)
