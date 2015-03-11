# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
Item.create!(
  [ { title: 'Web Development with Rails',
      description: 'Rails is constantly evolving and, as it does, so has this book.',
      type: 'book'
    },
    { title: 'Learn Rails the Hard Way',
      description: 'Rails is a useful tool.',
      type: 'book'
    },
    { title: 'Mac',
      description: 'The Macintosh or Mac, is a series of personal computers (PCs) designed, developed, and marketed by Apple Inc.',
      type: 'computer'
    } 
  ] )

