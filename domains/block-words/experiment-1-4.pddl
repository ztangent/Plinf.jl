(define (problem block_words)
	(:domain block-words)
	(:objects
		p o w e r c - block
	)
	(:init
		(handempty)

		(clear o)
		(on o w)
		(ontable w)

		(clear p)
		(on p r)
		(ontable r)

		(clear e)
		(on e c)
		(ontable c)
	)
	(:goal (and
		;; crow
		(clear c) (ontable w) (on c r) (on r o) (on o w)
	))
)
