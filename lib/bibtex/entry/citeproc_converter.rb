class BibTeX::Entry::CiteProcConverter
  CSL_FILTER = Hash.new { |h, k| k }.merge(Hash[*%w{
    date      issued
    isbn      ISBN
    booktitle container-title
    journal   container-title
    series    collection-title
    address   publisher-place
    pages     page
    number    issue
    url       URL
    doi       DOI
    year      issued
    type      genre
  }.map(&:intern)]).freeze

  CSL_FIELDS = %w{
    abstract annote archive archive_location archive-place
    authority call-number chapter-number citation-label citation-number
    collection-title container-title DOI edition event event-place
    first-reference-note-number genre ISBN issue jurisdiction keyword locator
    medium note number number-of-pages number-of-volumes original-publisher
    original-publisher-place original-title page page-first publisher
    publisher-place references section status title URL version volume
    year-suffix accessed container event-date issued original-date
    author editor translator recipient interviewer publisher composer
    original-publisher original-author container-author collection-editor
  }.map(&:intern).freeze

  CSL_TYPES = Hash.new { |h, k| k }.merge(Hash[*%w{
    booklet        pamphlet
    conference     paper-conference
    inbook         chapter
    incollection   chapter
    inproceedings  paper-conference
    manual         book
    mastersthesis  thesis
    misc           article
    phdthesis      thesis
    proceedings    paper-conference
    techreport     report
    unpublished    manuscript
    article        article-journal
  }.map(&:intern)]).freeze

  def self.convert(bibtex, options = {})
    new(bibtex, options).convert!
  end

  def initialize(bibtex, options = {})
    @bibtex = bibtex
    @options = { quotes: [] }.merge(options)
  end

  def convert!
    bibtex.parse_names
    bibtex.parse_month

    bibtex.each_pair do |key, value|
      hash[CSL_FILTER[key].to_s] = value.to_citeproc(options) unless BibTeX::Entry::DATE_FIELDS.include?(key)
    end

    methods = self.class.instance_methods(false) - [:convert!]
    methods.each { |m| send(m) }

    hash
  end

  def date
    return unless bibtex.field?(:year)

    case bibtex[:year].to_s
    when /^\d+$/
      parts = [bibtex[:year].to_s]

      if bibtex.field?(:month)
        parts.push BibTeX::Entry::MONTHS.find_index(bibtex[:month].to_s.intern)
        parts[1] = parts[1] + 1 unless parts[1].nil?
      end

      hash['issued'] = { 'date-parts' => [parts.compact.map(&:to_i)] }
    else
      hash['issued'] = { 'literal' => bibtex[:year].to_s }
    end
  end

  def key
    hash['id'] = bibtex.key.to_s
  end

  def type
    hash['type'] = CSL_TYPES[bibtex.type].to_s

    return if hash.key?('genre')
    case bibtex.type
    when :mastersthesis
      hash['genre'] = "Master's thesis"
    when :phdthesis
      hash['genre'] = 'PhD thesis'
    end
  end

  private

  attr_reader :bibtex, :options

  def hash
    @hash ||= {}
  end
end
