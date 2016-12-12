using System.Runtime.Serialization;

namespace WebAPIClient
{
    [DataContractAttribute(Name="repo")]
    public class Repository
    {
        [DataMemberAttribute(Name="name")]
        public string Name {get; set;}

        [DataMemberAttribute(Name="description")]
        public string Description { get; set; }

        [DataMemberAttribute(Name="html_url")]
        public Uri GitHubHomeUrl { get; set; }

        [DataMemberAttribute(Name="homepage")]
        public Uri Homepage { get; set; }

        [DataMemberAttribute(Name="watchers")]
        public int Watchers { get; set; }

    }
}