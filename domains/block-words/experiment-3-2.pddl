(define (problem block_words)
	(:domain block-words)
	(:objects
		c r o w e a d p - block
	)
	(:init
		(handempty)

		(clear d)
		(on d o)
		(on o p)
		(ontable p)

		(clear w)
		(on w c)
		(ontable c)

		(clear a)
		(on a e)
		(on e r)
		(ontable r)
	)
	(:goal (and
		;; cower
		(clear c) (ontable r) (on c o) (on o w) (on w e) (on e r)
	))
)
