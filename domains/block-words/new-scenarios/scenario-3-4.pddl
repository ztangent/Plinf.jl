(define (problem block_words)
	(:domain block-words)
	(:objects
		p o w e r c - block
	)
	(:init
		(handempty)

		(clear r)
		(ontable r)

		(clear c)
		(ontable c)

		(clear p)
		(ontable p)

		(clear w)
		(on w e)
		(on e o)
		(ontable o)
	)
	(:goal (and
		;; pore
		(clear p) (ontable e) (on r e) (on o r) (on p o)
	))
)
