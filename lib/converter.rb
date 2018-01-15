require 'csv'
require 'active_support'
class Converter
  class << self
    def csv_header(target, prefix = nil)
      case target
      when Hash
        target.map do |key, value|
          csv_header(value, prepare_prefix(prefix, key))
        end.flatten
      when Array
        target.each_with_index.map do |object, i|
          csv_header(object, prepare_prefix(prefix, i))
        end.flatten
      else
        prefix.to_s
      end
    end

    def json_path(json, path)
      case json
      when Hash
        json = json.with_indifferent_access
        json_path(json[leftmost_path(path)], rest_of_path(path))
      when Array
        json_path(json[leftmost_path(path).to_i], rest_of_path(path))
      else
        path == '' ? json.to_s : '' # trying to traverse even more?
      end
    end

    def array_of_hashes_to_csv(array)
      header = generate_master_header(array)

      body = array.inject([]) do |buff, hash|
        buff.push hash_to_csv(hash, header: header, skip_header: true)
      end

      header.to_csv + body.join
    end

    def hash_to_csv(hash, header: csv_header(hash), skip_header: false)
      output = header.inject([]) do |buff, column|
        buff.push json_path(hash, column)
      end

      if skip_header
        output.to_csv
      else
        header.to_csv + output.to_csv
      end
    end

    def csv_to_hash(csv)
      header, *lines = csv.split /\n|\r/ # csv can end with \r or \n

      header = header.to_s.split(',')

      lines.inject([]) do |objects, current_line|
        values = current_line.split(',')

        objects << header.each_with_index.inject({}) do |buff, (path, index)|
          json_path_set(buff, path, values[index])
        end
      end
    end

    def json_path_set(json, path, value)
      return value if path == ''

      current = leftmost_path(path)

      if current.to_i.to_s == current # number?
        json = [] unless json.is_a? Array
        case json[current.to_i]
        when nil
          json[current.to_i] = json_path_set({}, rest_of_path(path), value)
        else
          json[current.to_i] = json_path_set(json[current.to_i], rest_of_path(path), value)
        end
      else
        case json[current]
        when Array
          json[current] = json_path_set(json[current], rest_of_path(path), value)
        when Hash
          json[current].deep_merge! json_path_set({}, rest_of_path(path), value)
        when nil
          json[current] = json_path_set({}, rest_of_path(path), value)
        end
      end

      json
    end

    private

    def generate_master_header(array)
      master_header = array.inject([]) do |total, current_hash|
        total.push(csv_header(current_hash))
      end

      master_header.flatten.uniq
    end

    def rest_of_path(path)
      path.split('.')[1..-1].join('.')
    end

    def leftmost_path(path)
      path.split('.')[0]
    end

    def prepare_prefix(a, b)
      return b unless a

      "#{a}.#{b}"
    end
  end
end
