(define (problem block_words)
	(:domain block-words)
	(:objects
		p o w e r c a b - block
	)
	(:init
		(handempty)

		(clear w)
		(on w p)
		(ontable p)

		(clear o)
		(on o e)
		(on e c)
		(ontable c)

		(clear r)
		(ontable r)

		(clear a)
		(ontable a)
		(clear b)
		(ontable b)
	)
	(:goal (and
		;; power
		(clear p) (ontable r) (on p o) (on o w) (on w e) (on e r)
	))
)
