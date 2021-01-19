(define (problem block_words)
	(:domain block-words)
	(:objects
		d r a w p e - block
	)
	(:init
		(handempty)

		(clear d)
		(on d a)
		(on a e)
		(ontable e)

		(clear p)
		(ontable p)

		(clear r)
		(ontable r)

		(clear w)
		(ontable w)


	)
	(:goal (and
		;; draw
		(clear d) (ontable w) (on a w) (on r a) (on d r)
	))
)
