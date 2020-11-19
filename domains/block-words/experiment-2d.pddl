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
		(ontable e)

		(clear r)
		(on r d)
		(ontable d)

		(clear p)
		(on p w)
		(ontable w)
	)
	(:goal (and
		;; draw
		(clear d) (ontable w) (on d r) (on r a) (on a w)
	))
)
