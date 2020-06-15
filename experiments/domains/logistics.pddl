;; logistics domain typed version.

(define (domain logistics)
  (:requirements :strips :typing)
  (:types city place physobj - object
          package vehicle - physobj
          truck airplane - vehicle
          airport location - place
  )
  (:predicates
	(in-city ?loc - place ?city - city)
	(at ?obj - physobj ?loc - place)
	(in ?pkg - package ?veh - vehicle)
  )
  (:action load-truck
    :parameters (?pkg - package ?truck - truck ?loc - place)
    :precondition (and (at ?truck ?loc) (at ?pkg ?loc))
    :effect (and (not (at ?pkg ?loc)) (in ?pkg ?truck))
  )
  (:action load-airplane
   :parameters (?pkg - package ?airplane - airplane ?loc - place)
   :precondition (and (at ?pkg ?loc) (at ?airplane ?loc))
   :effect (and (not (at ?pkg ?loc)) (in ?pkg ?airplane))
  )
  (:action unload-truck
   :parameters (?pkg - package ?truck - truck ?loc - place)
   :precondition (and (at ?truck ?loc) (in ?pkg ?truck))
   :effect (and (not (in ?pkg ?truck)) (at ?pkg ?loc))
  )
  (:action unload-airplane
   :parameters (?pkg - package ?airplane - airplane ?loc - place)
   :precondition (and (in ?pkg ?airplane) (at ?airplane ?loc))
   :effect (and (not (in ?pkg ?airplane)) (at ?pkg ?loc))
  )
  (:action drive-truck
   :parameters (?truck - truck ?loc_from - place ?loc_to - place ?city - city)
   :precondition (and (at ?truck ?loc_from) (in-city ?loc_from ?city)
	 										(in-city ?loc_to ?city) (not (= ?loc_from ?loc_to)))
   :effect (and (not (at ?truck ?loc_from)) (at ?truck ?loc_to))
  )
  (:action fly-airplane
   :parameters (?airplane - airplane ?loc_from - airport ?loc_to - airport)
   :precondition (and (at ?airplane ?loc_from) (not (= ?loc_from ?loc_to)))
   :effect (and (not (at ?airplane ?loc_from)) (at ?airplane ?loc_to))
  )
)
