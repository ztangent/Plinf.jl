(define (problem block_words)
	(:domain block-words)
	(:objects
		c r o w e a d p - block
	)
	(:init
		(handempty)

		(clear d)
		(on d p)
		(on p o)
		(ontable o)

		(clear e)
		(on e w)
		(ontable w)

		(clear c)
		(ontable c)

		(clear a)
		(ontable a)

		(clear r)
		(ontable r)
	)
	(:goal (and
		;; core
		(clear c) (ontable e) (on c o) (on o r) (on r e)
	))
)
