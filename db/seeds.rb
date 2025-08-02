# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create sample events for the Yeardle game
tech_events = [
  { name: "First iPhone released", year: 2007, category: "Tech", description: "Apple releases the first iPhone, revolutionizing smartphones" },
  { name: "Google founded", year: 1998, category: "Tech", description: "Larry Page and Sergey Brin found Google" },
  { name: "Facebook launches", year: 2004, category: "Tech", description: "Mark Zuckerberg launches Facebook from Harvard" },
  { name: "World Wide Web invented", year: 1989, category: "Tech", description: "Tim Berners-Lee invents the World Wide Web" },
  { name: "Personal computer IBM PC released", year: 1981, category: "Tech", description: "IBM releases the IBM Personal Computer" },
  { name: "YouTube founded", year: 2005, category: "Tech", description: "Chad Hurley, Steve Chen, and Jawed Karim found YouTube" },
  { name: "Netflix streaming service launches", year: 2007, category: "Tech", description: "Netflix launches its streaming video service" },
  { name: "Amazon founded", year: 1994, category: "Tech", description: "Jeff Bezos founds Amazon as an online bookstore" },
  { name: "Twitter launches", year: 2006, category: "Tech", description: "Jack Dorsey, Noah Glass, Biz Stone, and Evan Williams launch Twitter" },
  { name: "Microsoft founded", year: 1975, category: "Tech", description: "Bill Gates and Paul Allen found Microsoft" }
]

sports_events = [
  { name: "First FIFA World Cup", year: 1930, category: "Sports", description: "The first FIFA World Cup held in Uruguay" },
  { name: "Michael Jordan's final NBA championship", year: 1998, category: "Sports", description: "Chicago Bulls win their 6th championship with Michael Jordan" },
  { name: "Barcelona Olympic Games", year: 1992, category: "Sports", description: "Summer Olympics held in Barcelona, Spain" },
  { name: "Miracle on Ice", year: 1980, category: "Sports", description: "US hockey team defeats Soviet Union at Winter Olympics" },
  { name: "Muhammad Ali vs. Sonny Liston", year: 1964, category: "Sports", description: "Muhammad Ali defeats Sonny Liston for heavyweight title" },
  { name: "Babe Ruth's called shot", year: 1932, category: "Sports", description: "Babe Ruth's famous called shot home run in World Series" },
  { name: "Tiger Woods wins Masters", year: 1997, category: "Sports", description: "Tiger Woods wins his first Masters Tournament at age 21" },
  { name: "Dream Team Olympics", year: 1992, category: "Sports", description: "US basketball Dream Team dominates Olympics" },
  { name: "Pelé's first World Cup victory", year: 1958, category: "Sports", description: "17-year-old Pelé helps Brazil win World Cup" },
  { name: "First Super Bowl", year: 1967, category: "Sports", description: "Green Bay Packers defeat Kansas City Chiefs in first Super Bowl" }
]

history_events = [
  { name: "Fall of Berlin Wall", year: 1989, category: "History", description: "The Berlin Wall falls, symbolizing the end of the Cold War" },
  { name: "Moon landing", year: 1969, category: "History", description: "Apollo 11 lands on the moon, Neil Armstrong takes first steps" },
  { name: "World War II ends", year: 1945, category: "History", description: "World War II officially ends with Japan's surrender" },
  { name: "Martin Luther King Jr.'s 'I Have a Dream' speech", year: 1963, category: "History", description: "MLK delivers famous speech during March on Washington" },
  { name: "JFK assassination", year: 1963, category: "History", description: "President John F. Kennedy assassinated in Dallas" },
  { name: "Titanic sinks", year: 1912, category: "History", description: "RMS Titanic sinks on its maiden voyage" },
  { name: "Pearl Harbor attack", year: 1941, category: "History", description: "Japan attacks Pearl Harbor, bringing US into WWII" },
  { name: "Chernobyl nuclear disaster", year: 1986, category: "History", description: "Nuclear reactor explodes in Chernobyl, Ukraine" },
  { name: "Nelson Mandela released from prison", year: 1990, category: "History", description: "Nelson Mandela freed after 27 years in prison" },
  { name: "D-Day landings", year: 1944, category: "History", description: "Allied forces land in Normandy during World War II" }
]

culture_events = [
  { name: "Beatles release 'Sgt. Pepper's'", year: 1967, category: "Culture", description: "The Beatles release Sgt. Pepper's Lonely Hearts Club Band" },
  { name: "Woodstock festival", year: 1969, category: "Culture", description: "Iconic music festival held in upstate New York" },
  { name: "MTV launches", year: 1981, category: "Culture", description: "Music Television begins broadcasting" },
  { name: "Star Wars original film release", year: 1977, category: "Culture", description: "George Lucas releases the original Star Wars film" },
  { name: "The Simpsons TV series begins", year: 1989, category: "Culture", description: "The Simpsons animated series premieres" },
  { name: "Michael Jackson's 'Thriller' album", year: 1982, category: "Culture", description: "Michael Jackson releases the best-selling album of all time" },
  { name: "Live Aid concerts", year: 1985, category: "Culture", description: "Benefit concerts held simultaneously in London and Philadelphia" },
  { name: "Nirvana's 'Nevermind' album", year: 1991, category: "Culture", description: "Nirvana releases Nevermind, popularizing grunge music" },
  { name: "Saturday Night Fever release", year: 1977, category: "Culture", description: "John Travolta stars in Saturday Night Fever" },
  { name: "Madonna's first album", year: 1983, category: "Culture", description: "Madonna releases her self-titled debut album" }
]

all_events = tech_events + sports_events + history_events + culture_events

all_events.each do |event_data|
  Event.find_or_create_by!(name: event_data[:name]) do |event|
    event.year = event_data[:year]
    event.category = event_data[:category]
    event.description = event_data[:description]
  end
end

puts "Created #{Event.count} events"
