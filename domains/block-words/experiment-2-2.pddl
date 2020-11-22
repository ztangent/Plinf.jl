(define (problem block_words)
	(:domain block-words)
	(:objects
		p o w e r c - block
	)
	(:init
		(handempty)

		(clear o)
		(on o r)
		(on r w)
		(ontable w)

		(clear p)
		(on p c)
		(ontable c)

		(clear e)
		(ontable e)

	)
	(:goal (and
		;; pore
		(clear p) (ontable e) (on p o) (on o r) (on r e)
	))
)
