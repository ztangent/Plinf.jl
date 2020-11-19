(define (problem block_words)
	(:domain block-words)
	(:objects
		d r a w p e - block
	)
	(:init
		(handempty)

		(clear w)
		(ontable w)

		(clear a)
		(on a r)
		(ontable r)

		(clear d)
		(on d e)
		(ontable e)

		(ontable p)
		(clear p)
	)
	(:goal (and
		;; draw
		(clear d) (ontable w) (on d r) (on r a) (on a w)
	))
)
