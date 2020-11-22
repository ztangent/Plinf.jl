(define (problem block_words)
	(:domain block-words)
	(:objects
		p o w e r c - block
	)
	(:init
		(handempty)

		(clear r)
		(on r w)
		(ontable w)

		(clear c)
		(on c p)
		(on p o)
		(ontable o)

		(clear e)
		(ontable e)
	)
	(:goal (and
		;; core
		(clear c) (ontable e) (on c o) (on o r) (on r e)
	))
)
